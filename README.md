# Bildaro: Jekyll Photo Gallery

Bildaro is a mobile-friendly photo gallery using affordable, serverless storage and static web hosting.

It also includes a handy image processor tool that creates resized images for you and uploads album assets to S3.

![Bildaro: Album example](/docs/images/screenshot-01.webp?raw=true "Bildaro: Photo album example")

Bildaro, powered by Jekyll and AWS, allows you to host your own serverless photo gallery and pay a fraction of the cost of other hosted galleries. The estimated monthly cost for storing 1 GB of photos and serving 10 GB of traffic is about $2/month!

Since Bildaro is serverless, there's no software to provision or maintain, no SSL certs to manage, no database to lock down, and no site for anyone to hack. Just a slick, easy to use, free to customize photo gallery to suit your needs!

*Bildaro* is the Esperanto word meaning "a collection of images."

## Demo

Check out [my personal photo gallery](https://photos.gaelanlloyd.com) to see Bildaro in action!

## Features

- Completely static, maintenance-free, serverless web photo gallery
- Simple: no package managers or complicated third-party libraries
- Teeny tiny
  - 1.3 KB homepage
  - 1.8 KB CSS (split in critical and non-critical styles)
  - 0.6 KB JS (only 40 lines of JS used to display the lightbox)
- Album features
  - Public and private (unlisted) albums
  - One-click download of ZIP containing original album image files
- Image processor handles your photos
  - Creates thumbnails and medium-sized images in modern, efficient `webp` format
  - Creates the album download ZIP of all the full-sized `jpg` images
  - Uploads everything to your AWS S3 bucket for you
  - Creates an album post with a list of all the images
- RSS feed advertises your gallery's activity

## Change log

Major functionality changes are listed here. Smaller changes are documented in the repo commit log.

- 2025-06-16
  - UX improvements (buttons stay in the same place as you navigate between photos).
  - Progress reporting during batch image processing.
- 2024-11-30
  - Fixed private image support (now their own post collection).
  - Added modal previous/next image browsing capability, with keyboard support.
- 2024-11-12
  - Initial release.

## Dependencies

- `imagemagick` via `magick` (Mac: `brew install imagemagick`)
- `pip` (Mac: `brew install pipx`)
- `awscli` (Mac: `pipx install awscli`)
  - Configure `awscli` with the creds created in the next step
- `ruby` and these gems:
  - `jekyll`
  - `bundler`
  - `jekyll-sitemap`
- A bucket on AWS S3 to store images
  - To prevent excessive bandwidth, prevent image hotlinking in bucket (see below)
  - For safety, create an AWS user with access to only manage files in that bucket (see below)
- Connect this repo to AWS Amplify to publish the gallery website to the web

## Instructions

Install all the dependencies above.

Clone this repo to your machine.

In the repo root, install Jekyll dependencies:

```bash
bundle install
```

Set up the environment file
- Copy `env.sh.sample` to `env.sh`
- Edit the file and add your custom settings

Set up `_config.yml`
- Set `url` to your site's URL
- Set `image_store` to your S3 bucket public URL (will look like `https://YOURBUCKETNAMEGOESHERE.s3-us-west-2.amazonaws.com/`)
- Edit these fields and set them to something appropriate: `title`, `description`, `author`, `home_header_title`, and `home_header_image`

In a temporary path on your system, create a folder containing the photos you want in the album
- Use the naming scheme `YYYY-MM-DD-album-name-like-this` (all lowercase album name with hyphens as spaces)
  - It's important to use that naming scheme. Jekyll will use it to gather the album date and title, and the folder storing the images will also be named that in S3.
- Add photos directly to that folder (currently only `JPG` or `jpg` are supported).

Run the image processor on that folder. The script will:
- Create thumbnails (250px x 250px center-weighted cropped)
- Create medium sized images for in-browser viewing (800px high x proportional width)
- Creates a ZIP file containing all original sized images for one-click album downloads
- Uploads all of that to your AWS S3 bucket
- Creates an album post under `_posts` with a list of all the images

```bash
./image-processor.sh /your/folder/name
```

Edit the new post:
- Change the album title
- Change the album cover

To make the album private (unlisted), move the album post to the `_private` folder.
- NOTE: This doesn't make the album completely hidden or password protected, it just removes it from the album listings, sitemap, etc. Anyone with the album URL will be able to see the album.
- The album will be available under the `/private/` path instead of `/album/` using the same naming convention as other albums.

Spin up and serve the site locally to review the new album:

```bash
bundle exec jekyll serve
```

If everything looks good, commit the new post to the repo, which will trigger a deployment on AWS Amplify. Et voila!

Once you see the images up on the gallery, you can delete the temporary image working folder you made earlier.

## Notes

### Preventing image hotlinking

You can protect your S3 bucket from hotlinking by adding the following policy. It'll help ensure that images added to the bucket aren't directly served from other sites, which could incur large bandwidth fees.

```json
{
  "Version": "2008-10-17",
  "Id": "Asset hotlink protection",
  "Statement": [
    {
      "Sid": "Allow get requests only from authorized domains",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::YOURBUCKETNAMEGOESHERE/*",
      "Condition": {
        "StringLike": {
          "aws:Referer": [
            "http://localhost:4000/*",
            "https://localhost:4000/*",
            "http://127.0.0.1:4000/*",
            "https://127.0.0.1:4000/*",
            "https://www.YOURDOMAIN.com/*",
          ]
        }
      }
    }
  ]
}
```

### AWS S3 uploader user

For higher security, limit `aws cli` to a user that only has write access to the S3 gallery bucket. Create a user with a security policy like the following. Replace `YOURBUCKETNAMEGOESHERE` with your S3 bucket's name.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect": "Allow",
        "Action": [
            "s3:ListAllMyBuckets"
        ],
        "Resource": "arn:aws:s3:::*"
    },
    {
        "Effect": "Allow",
        "Action": [
            "s3:ListBucket",
            "s3:GetBucketLocation",
            "s3:AbortMultipartUpload",
            "s3:GetBucketPolicy",
            "s3:GetObject",
            "s3:PutObject"
        ],
        "Resource": "arn:aws:s3:::YOURBUCKETNAMEGOESHERE"
    },
    {
        "Effect": "Allow",
        "Action": [
            "s3:ListBucket",
            "s3:GetBucketLocation",
            "s3:AbortMultipartUpload",
            "s3:GetBucketPolicy",
            "s3:GetObject",
            "s3:PutObject"
        ],
        "Resource": "arn:aws:s3:::YOURBUCKETNAMEGOESHERE/*"
    }
  ]
}
```

## Author

Bildaro was created in 2024 by [Gaelan Lloyd](https://www.gaelanlloyd.com) on a drizzly Seattle Sunday and is provided to you via the MIT license.
