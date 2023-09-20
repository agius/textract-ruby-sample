require 'aws-sdk-s3'
require 'aws-sdk-textract'

class TextractClient
  attr_reader :client, :s3_client, :bucket_name

  def initialize
    @client = Aws::Textract::Client.new
    @s3_client = Aws::S3::Client.new
    @bucket_name = ENV.fetch('TEXTRACT_BUCKET') # raise an error if this isn't set
  end

  def analyze_document(filepath)
    raise ArgumentError.new("#{filepath} not found") unless File.exist?(filepath)
    raise 'Please only upload PDF files' unless File.extname(filepath) == '.pdf'

    # NOTE: in Rails prod setups, the object is likely already on S3 and we don't need
    # to upload it to a separate bucket
    obj_key = upload_to_s3(filepath)

    job_id = start_analysis_job(obj_key)
    wait_for_analysis(job_id)
    fetch_analysis(job_id)
  end

  def start_analysis_job(obj_key)
    # client request token to prevent running duplicate analyses on the same S3 obj
    # length needs to be limited to 64chars, so we use a hash instead of the full filename
    client_token = Digest::SHA256.hexdigest(obj_key)

    resp = client.start_document_analysis(
      document_location: {
        s3_object: {
          bucket: bucket_name,
          name: obj_key
        }
      },
      feature_types: ['TABLES'],
      client_request_token: client_token
    )

    resp.job_id
  end

  DEFAULT_WAIT_INTERVAL = 5 # in seconds, used for sleep calls
  DEFAULT_MAX_WAIT_INTERVALS = 10

  def wait_for_analysis(job_id, wait_interval: DEFAULT_WAIT_INTERVAL, max_wait_intervals: DEFAULT_MAX_WAIT_INTERVALS)
    count = 0
    begin
      resp = client.get_document_analysis(
        job_id: job_id,
        max_results: 1
      )
      sleep(wait_interval) if resp.job_status == 'IN_PROGRESS'
    end while resp.job_status == 'IN_PROGRESS' && count < max_wait_intervals
  end

  def fetch_analysis(job_id)
    resp = client.get_document_analysis(
      job_id: job_id
    )

    blocks = resp.blocks
    warnings = resp.warnings

    unless ['SUCCEEDED', 'PARTIAL_SUCCESS'].include?(resp.job_status)
      raise "Job #{job_id} has status #{resp.job_status} | #{resp.inspect}"
    end

    while resp.next_token.to_s.length > 0
      resp = client.get_document_analysis(
        job_id: job_id,
        next_token: resp.next_token
      )

      blocks += resp.blocks
      warnings += resp.warnings
    end

    # TODO: build blocks_map, then build Node tree from data, using node_type == PAGE as root nodes
    Result.new(blocks: blocks, warnings: warnings)
  end

  def upload_to_s3(filepath)
    key = File.basename(filepath).gsub(/\W+/, '_').squeeze("_")
    File.open(filepath, 'rb') do |file|
      s3_client.put_object(
        body: file,
        bucket: bucket_name,
        key: key
      )
    end
    key
  end
end
