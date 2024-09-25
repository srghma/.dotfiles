#!/usr/bin/env bash


##! /usr/bin/env nix-shell
##! nix-shell -i bash -p pandoc texlive.combined.scheme-full

# Define the directory
TARGET_DIR="/home/srghma/Insync/srghma@gmail.com/Google Drive/public/unsorted/2024 unsorted/Greg Egan"
TARGET_DIR="/home/srghma/Insync/srghma@gmail.com/Google Drive/public/unsorted/2024 unsorted"

# Array to store the names of converted files
converted_files=()

# Create a temporary LaTeX template
# template_file=$(mktemp /tmp/template.XXXXXX.tex)
# cat <<EOF > "$template_file"
# \documentclass[12pt]{article}
# \usepackage{fontspec}
# \usepackage{geometry}
# \usepackage{graphicx}
# \geometry{margin=0.3in}
# \setmainfont{Noto Serif}
# \begin{document}
# \$body\$
# \end{document}
# EOF

# Function to convert files using pandoc
convert_file() {
  local input_file=$1
  local output_file=$2

  if [ -f "$output_file" ]; then
    echo "Removing existing $output_file"
    rm "$output_file"
  fi

  echo "Converting $input_file to $output_file"
  # pandoc "$input_file" -o "$output_file" --pdf-engine=wkhtmltopdf
  # pandoc "$input_file" -o "$output_file"
  # pandoc "$input_file" -o "$output_file" --pdf-engine=xelatex --variable mainfont="Liberation Serif" --variable geometry="margin=0.3in"
  # pandoc "$input_file" -o "$output_file" --pdf-engine=lualatex --variable mainfont="Noto Serif" --variable geometry="margin=0.3in" --variable "fontsize=20pt"
  # pandoc "$input_file" -o "$output_file" --pdf-engine=xelatex --variable mainfont="Noto Serif" --variable geometry="margin=0.3in" --variable "fontsize=20pt"
  # pandoc "$input_file" -o "$output_file" --pdf-engine=lualatex --template="$template_file"
  pandoc "$input_file" -o "$output_file" --pdf-engine=xelatex --variable mainfont="Liberation Serif" --variable geometry="margin=0.3in" --variable documentclass="article" --variable "fontsize=20pt" --variable "classoptions=20pt"
  # pandoc "$input_file" -o "$output_file" --pdf-engine=xelatex --variable mainfont="Noto Serif" --variable geometry="margin=0.3in" --variable documentclass="article" --variable "fontsize=20pt" --variable "classoptions=20pt"

  # local input_dir
  # input_dir=$(dirname "$input_file")
  # echo "Changing directory to $input_dir"
  # cd "$input_dir" || { echo "Failed to change directory to $input_dir"; return 1; }
  # soffice --headless --convert-to pdf "$input_file"

  # soffice --headless --convert-to pdf:writer_pdf_Export --infilter=fb2 "$input_file" \
  #   && echo "Conversion successful: $output_file" \
  #   || echo "Conversion failed for $input_file"

  # ebook-convert "$input_file" "$output_file" --pdf-margin-top 0.4in --pdf-margin-bottom 0.4in pdf-margin-left 0.4in --pdf-margin-right 0.4in
  # ebook-convert "$input_file" "$output_file"
  # ebook-convert "$input_file" "$output_file" --paper-size a4 --pdf-page-size 8.5x11

  if [ $? -eq 0 ]; then
    converted_files+=("$output_file")
  else
    echo "Conversion failed for $input_file"
  fi
}

# Combined function to process .epub and .fb2 files
process_files() {
  local maxdepth="${1:-1}"  # Default to 1 if not specified

  find "$TARGET_DIR" -maxdepth "$maxdepth" -type f \( -name "*.epub" -o -name "*.fb2" \) | while read -r file; do
    case "$file" in
      *.epub)
        local pdf_file="${file%.epub}-my.pdf"
        convert_file "$file" "$pdf_file"
        ;;
      *.fb2)
        local pdf_file="${file%.fb2}-my.pdf"
        # convert_file "$file" "$pdf_file"
        ;;
    esac
  done
}

# Function to print a summary of the converted files
print_summary() {
  echo
  echo "Summary of converted files:"
  if [ ${#converted_files[@]} -eq 0 ]; then
    echo "No files were converted."
  else
    for file in "${converted_files[@]}"; do
      echo "Converted: $file"
    done
  fi
}

process_files
print_summary
