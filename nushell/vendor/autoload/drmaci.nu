# Stop and remove all Docker containers
def drmaci [] {
    let ids = (docker ps -aq | lines)
    if ($ids | is-not-empty) {
        docker stop ...$ids
        docker rm ...$ids
    } else {
        print "No containers to remove."
    }
}
