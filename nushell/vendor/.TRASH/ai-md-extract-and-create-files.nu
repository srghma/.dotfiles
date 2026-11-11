module _md_extract {
    use ../lib/log.nu [log-info, log-header, log-err, log-done]

    # Strips delimiter characters (` * : # and spaces) from boundaries of a token
    # Supports both pipeline input ($str | clean-token) and argument (clean-token $str)
    def clean-token [raw?: string] {
        let text = if ($raw != null) { $raw } else { $in }
        $text | str replace -r '^[\s`*:#]+' '' | str replace -r '[\s`*:#]+$' ''
    }

    # Checks for banner format: ==== FILE: path ====
    def match-file-banner [line: string] {
        if ($line =~ '^={3,}\s*FILE:\s*([^\s=]+)') {
            let parsed = ($line | parse -r '^={3,}\s*FILE:\s*([^\s=]+)')
            if ($parsed | is-not-empty) {
                return ($parsed | get 0.capture0 | str trim)
            }
        }
        ""
    }

    # Checks for markdown heading format: ### 1. `path` or ### path
    def match-heading-path [line: string] {
        if not ($line =~ '^#{1,4}\s+') {
            return ""
        }

        # 1. Check for backticked filename token first
        let backticked = ($line | parse -r '`([^`]+)`')
        if ($backticked | is-not-empty) {
            let candidate = ($backticked | get 0.capture0 | str trim)
            if ($candidate =~ '[\.\/]') and not ($candidate =~ '\s') {
                return $candidate
            }
        }

        # 2. Fallback: heading without backticks, e.g. "### 1. path/to/file.ts"
        let stripped = ($line | str replace -r '^#{1,4}\s+(?:\d+[\.\)]\s*)?' '' | str trim)
        let first_token = (clean-token ($stripped | split row ' ' | get 0))
        if ($first_token =~ '[\.\/]') and ($first_token =~ '[a-zA-Z0-9_\-\[\]]+\.[a-zA-Z0-9_-]+$') {
            return $first_token
        }

        ""
    }

    # Inspects a line and extracts a file path if the line represents a valid file header
    def extract-file-path [line: string] {
        let trimmed = ($line | str trim)

        let banner_path = (match-file-banner $trimmed)
        if ($banner_path | is-not-empty) {
            return $banner_path
        }

        match-heading-path $trimmed
    }

    # Code fence checkers
    def is-fence-close [line: string] {
        ($line | str trim) =~ '^```\s*$'
    }

    def is-fence-open [line: string] {
        ($line | str trim) =~ '^```'
    }

    def is-markdown-heading [line: string] {
        let trimmed = ($line | str trim)
        ($trimmed =~ '^#{1,4}\s+') or ($trimmed =~ '^={3,}\s*FILE:')
    }

    # Parses raw Markdown into a table of [{ path, content }]
    def parse-markdown-files [raw_text: string] {
        let lines = ($raw_text | str replace -r '\r\n' "\n" | lines)
        mut files: list<any> = []
        mut current_path = ""
        mut current_lines: list<string> = []
        mut in_fence = false

        for line in $lines {
            if $in_fence {
                if (is-fence-close $line) {
                    if ($current_path | is-not-empty) {
                        $files = ($files | append {
                            path: $current_path,
                            content: ($current_lines | str join "\n")
                        })
                    }
                    $in_fence = false
                    $current_path = ""
                    $current_lines = []
                } else {
                    $current_lines = ($current_lines | append $line)
                }
            } else {
                if (is-markdown-heading $line) {
                    let detected = (extract-file-path $line)
                    if ($detected | is-not-empty) {
                        $current_path = $detected
                        $current_lines = []
                    } else {
                        # Non-file heading (e.g. "### Project File Structure"), clear pending
                        $current_path = ""
                    }
                } else if ($current_path | is-not-empty) and (is-fence-open $line) {
                    $in_fence = true
                    $current_lines = []
                }
            }
        }

        $files
    }

    # Resolves target file path relative to target base directory
    def resolve-target-path [base: path, rel_path: string] {
        if $base == "." {
            $rel_path
        } else {
            [$base, $rel_path] | path join
        }
    }

    # Ensures parent directory tree exists
    def ensure-parent-dir [file_path: string] {
        let parent_dir = ($file_path | path dirname)
        if ($parent_dir | is-not-empty) and not ($parent_dir | path exists) {
            mkdir $parent_dir
        }
    }

    # Prompts user when a file already exists and differs
    def prompt-overwrite [file_path: string] {
        let user_choice = (input $"  ⚠  File '(ansi yellow)($file_path)(ansi reset)' differs. Overwrite? [y/N/a/q]: ") | str trim | str lowercase
        match $user_choice {
            "a" | "all" => "all",
            "y" | "yes" => "overwrite",
            "q" | "quit" => "quit",
            _ => "skip",
        }
    }

    # Writes content to disk and displays status
    def write-file [full_path: string, content: string, is_update: bool] {
        ensure-parent-dir $full_path
        $content | save --raw --force $full_path

        if $is_update {
            print $"(ansi yellow)  ✔ Updated:(ansi reset) ($full_path)"
        } else {
            print $"(ansi green)  ✔ Created:(ansi reset) ($full_path)"
        }
    }

    # Extracts code blocks mapped to file paths from a Markdown file and writes them to disk
    export def ai-md-extract-and-create-files [
        markdown_file: path            # Path to markdown file containing the code blocks
        --target-dir (-d): path = "."  # Base directory to output files into (default: current directory)
        --force (-f)                   # Force overwrite existing files without confirmation
        --dry-run (-n)                 # Preview files that will be created/updated without writing
    ] {
        if not ($markdown_file | path exists) {
            log-err $"File not found: ($markdown_file)"
            return
        }

        log-header "Markdown File Extractor"
        log-info $"Reading: (ansi cyan)($markdown_file)(ansi reset)"

        let raw_content = (open --raw $markdown_file)
        let file_blocks = (parse-markdown-files $raw_content)
        let total = ($file_blocks | length)

        if $total == 0 {
            print $"(ansi yellow)⚠ No matching file blocks found in ($markdown_file)(ansi reset)"
            return
        }

        log-info $"Found ($total) file targets to process."

        mut written_count = 0
        mut skipped_count = 0
        mut unchanged_count = 0
        mut force_all = $force

        for item in $file_blocks {
            let full_path = (resolve-target-path $target_dir $item.path)
            let file_exists = ($full_path | path exists)
            let new_content = $"($item.content | str trim -r)\n"

            if $dry_run {
                if $file_exists {
                    print $"[DRY-RUN] (ansi yellow)UPDATE(ansi reset) -> ($full_path)"
                } else {
                    print $"[DRY-RUN] (ansi green)CREATE(ansi reset) -> ($full_path)"
                }
                continue
            }

            if $file_exists {
                let existing_content = (open --raw $full_path | str replace -r '\r\n' "\n")
                if $existing_content == $new_content {
                    print $"(ansi dark_gray)  ⏭ Unchanged: ($full_path)(ansi reset)"
                    $unchanged_count = $unchanged_count + 1
                    continue
                }

                if not $force_all {
                    let decision = (prompt-overwrite $full_path)
                    match $decision {
                        "all" => {
                            $force_all = true
                        },
                        "overwrite" => {
                            # proceed to write
                        },
                        "quit" => {
                            print $"(ansi yellow)⚠ Aborted by user.(ansi reset)"
                            break
                        },
                        "skip" | _ => {
                            print $"(ansi dark_gray)  ⏭ Skipped: ($full_path)(ansi reset)"
                            $skipped_count = $skipped_count + 1
                            continue
                        }
                    }
                }
            }

            write-file $full_path $new_content $file_exists
            $written_count = $written_count + 1
        }

        if not $dry_run {
            let summary = [
                $"(ansi green_bold)✔ Finished processing!(ansi reset)",
                $"  Created/Updated: ($written_count)",
                $"  Unchanged:       ($unchanged_count)",
                $"  Skipped:         ($skipped_count)"
            ] | str join "\n"
            print $summary
        }
    }
}

use _md_extract [ai-md-extract-and-create-files]
