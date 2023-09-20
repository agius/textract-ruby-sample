# AWS Textract Results in Ruby

Some example code for generating and handling document analyses from AWS Textract in Ruby. I've included an example PDF to parse if you want to run the code.

This isn't meant to be a useful tool on its own, just a starting point to show how you might run Textract jobs and inspect the results in Ruby. I'd make this into a library on top of Textract if I knew more use-cases, but right now the code is small enough that it's better you copy it into your codebase than rely on me to maintain it 😸

## Running It

1. `bundle install`
2. ensure `TEXTRACT_BUCKET` env var is set to a bucket name you control
3. ensure AWS CLI credentials are configured
4. run `bundle exec ruby script.rb`

This should upload the PDF to the S3 bucket, kick off a Textract analysis, then print the result in a nicely-indented tree-view.

Feel free to copy, make use of, and repurpose the code to your heart's content