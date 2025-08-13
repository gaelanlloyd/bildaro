#!/usr/bin/env bash

action=$1

path=$2

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

if [ "$action" = "adhoc" ]; then
	make_zip=false
	upload_to_s3=false
	create_manifest=false
else
	make_zip=true
	upload_to_s3=true
	create_manifest=true
fi

# Load in the environment variables
source env.sh

# --- FUNCTIONS ----------------------------------------------------------------

write_help() {
	echo ""
	echo "Proper syntax:"
	echo "  ./image-processor.sh [action] [album-path]"
	echo ""
	echo "Actions: create | adhoc"
	echo ""
}

# --- CHECK FOR ERRORS ---------------------------------------------------------

# Check if no parameters were provided
if [ $# -eq 0 ]; then
	echo ""
	echo "ERROR: No parameters given."
	write_help
	exit 1
fi

# Ensure path exists
if [ ! -e "$path" ]; then
	echo ""
	echo "ERROR: Source path [$path] does not exist."
	write_help
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

# --- DEBUG --------------------------------------------------------------------

echo "Action: [$action]"
echo ""

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

i=1
count=${#images[@]}

for file in "${images[@]}"; do

    echo "Processing $i/$count $file"

	webp_file=$(echo "$file" | sed -E 's/\.[jJ][pP][gG]$/.webp/')

    # Create thumbnails
    command=("$processor $file -auto-orient -strip -resize ${height_thumb}x${height_thumb}^ -gravity Center -extent ${height_thumb}x${height_thumb} -quality $quality_thumb $folder_thumb/$webp_file")
    # echo $command
    eval "$command"

    # Create medium sized images
    command=("$processor $file -auto-orient -strip -resize x${height_medium} -quality $quality_medium $folder_medium/$webp_file")
    # echo $command
    eval "$command"

	((i++))

done

# --- CREATE DOWNLOAD ZIP ------------------------------------------------------

if [ "$make_zip" = true ] ; then

	echo "Creating full-size image ZIP download file"
	zip "$zip_file" "${images[@]}" -q
	zip_filesize="$(du -k "$zip_file" | cut -f1)"

fi

# --- UPLOAD TO S3 -------------------------------------------------------------

if [ "$upload_to_s3" = true ]; then

	command=("aws s3 cp \"$path\" s3://$IMAGE_PROCESSOR_S3_BUCKET/$path_basename --recursive --exclude \".DS_Store\"")
	# echo $command
	eval "$command"

fi

# --- CREATE YAML MANIFEST -----------------------------------------------------

if [ "$create_manifest" = true ]; then

	post_file="_posts/${path_basename}.md"

	echo "Creating post: $SITE_PATH/$post_file"

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

fi

# ------------------------------------------------------------------------------


if [ "$action" = "adhoc" ]; then

	echo ""
	echo "Adhoc images ready."
	echo ""
	echo "Todo:"
	echo "[ ] Upload the files to S3."
	echo "[ ] Ensure the album post doesn't have the 'download_size' front matter variable defined."
	echo "[ ] Add these filenames to your album's post front matter manually:"
	echo ""

	for file in "${images[@]}"; do
		echo "  - $file"
	done

	echo ""

else

	echo ""
	echo "All set!"
	echo "Draft post created."
	echo "Adjust it as necessary, then commit and push the changes to the repo to deploy your album."
	echo ""

fi
