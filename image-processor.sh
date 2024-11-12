#!/usr/bin/env bash

path=$1

images=()

extensions=(
    "jpg"
    "JPG"
)

processor="magick"

height_thumb="250"
height_medium="800"

quality_thumb="70"
quality_medium="90"

folder_thumb="thumbs"
folder_medium="medium"

zip_file="download.zip"

# Load in the environment variables
source env.sh

# --- CHECK FOR ERRORS ---------------------------------------------------------

# Check if no parameters were provided
if [ $# -eq 0 ]; then
	echo ""
	echo "ERROR: No parameters given."
	echo ""
	echo "Proper syntax :"
	echo "  ./image-processor.sh [image-path]"
	echo ""
	exit 1
fi

# Ensure path exists
if [ ! -e "$path" ]; then
	echo ""
	echo "ERROR: [$path] does not exist."
	echo ""
	exit 1
fi

# Ensure that imagemagick exists
if ! command -v "$processor" >/dev/null 2>&1; then
	echo ""
	echo "ERROR: [$processor] is not installed or is not avilable in this path."
	echo ""
	exit 1
fi

# Ensure .env file exists
if [ ! -f "env.sh" ]; then
	echo ""
	echo "ERROR: [env.sh] does not exist. Copy it from [env.sh.sample] and edit the file."
	echo ""
	exit 1
fi

# Ensure the project path is defined
if [ ! "$SITE_PATH" ]; then
	echo ""
	echo "ERROR: [SITE_PATH] is not defined in [env.sh]."
	echo ""
	exit 1
fi

# Ensure AWS S3 bucket is defined
if [ ! "$IMAGE_PROCESSOR_S3_BUCKET" ]; then
	echo ""
	echo "ERROR: [IMAGE_PROCESSOR_S3_BUCKET] is not defined in [env.sh]."
	echo ""
	exit 1
fi

# ------------------------------------------------------------------------------

path_basename=$(basename "$path")

# List all JPGs in the working path
cd "$path" || { echo "Failed to change directory to [$path]"; exit 1; }

# Loop through all extensions and add any found images to the working array
for ext in "${extensions[@]}"; do
    for file in *."$ext"; do
        if [[ -f "$file" ]]; then
            images+=("$file")
        fi
    done
done

# List all found images
echo "Found ${#images[@]} image files"

# Create output directories
mkdir "$path/thumbs"
mkdir "$path/medium"

# --- MAKE IMAGE VARIANTS ------------------------------------------------------

# Iterate over each image and perform transformations

for file in "${images[@]}"; do

    echo "Processing $file"

	webp_file=$(echo "$file" | sed -E 's/\.[jJ][pP][gG]$/.webp/')

    # Create thumbnails
    command=("$processor $file -resize ${height_thumb}x${height_thumb}^ -gravity Center -extent ${height_thumb}x${height_thumb} -quality $quality_thumb $folder_thumb/$webp_file")
    # echo $command
    eval "$command"

    # Create medium sized images
    command=("$processor $file -resize x${height_medium} -quality $quality_medium $folder_medium/$webp_file")
    # echo $command
    eval "$command"

done

# --- CREATE DOWNLOAD ZIP ------------------------------------------------------

echo "Creating full-size image ZIP download file"

zip "$zip_file" "${images[@]}" -q

zip_filesize="$(du -k "$zip_file" | cut -f1)"

# --- UPLOAD TO S3 -------------------------------------------------------------

command=("aws s3 cp \"$path\" s3://$IMAGE_PROCESSOR_S3_BUCKET/$path_basename --recursive --exclude \".DS_Store\"")
# echo $command
eval "$command"

# --- CREATE YAML MANIFEST -----------------------------------------------------

post_file="_posts/${path_basename}.md"

echo "Creating post: $post_file"

# Return t
cd $SITE_PATH || { echo "Failed to change directory to [$SITE_PATH]"; exit 1; }

# Clear the file if it exists (first echo line is single >)
echo "---" > $post_file

echo "title: $path_basename" >> $post_file
echo "cover: ${images[0]}" >> $post_file
echo "download_size: $zip_filesize" >> $post_file
echo "pictures:" >> $post_file

for file in "${images[@]}"; do
    echo "  - $file" >> $post_file
done

echo "---" >> $post_file

echo "" >> $post_file

# ------------------------------------------------------------------------------

echo ""
echo "All set!"
echo "Make any changes you want to the post, then commit the changes to the repo to deploy!"
echo ""
