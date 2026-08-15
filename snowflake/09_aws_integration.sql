-- ============================================================================
-- 09_AWS_INTEGRATION.SQL — AWS services for Sukuk Portfolio Analytics
-- Account: 018437500440 | Region: ap-southeast-1
-- Skip this script for Snowflake-only build
-- ============================================================================
USE DATABASE ISLAMIC_SUKUK_PORTFOLIO;
USE SCHEMA APP;

-- ==================== AMAZON S3 ====================
-- Storage integration for S3 landing zone
CREATE OR REPLACE STORAGE INTEGRATION aws_malaysia_islamic_finance_sukuk_S3_INT
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::018437500440:role/snowflake-sea-demos-s3'
  ENABLED = TRUE
  STORAGE_ALLOWED_LOCATIONS = ('s3://sea-aws-demos-018437500440/aws-malaysia-islamic-finance-sukuk/');

-- External stage for data landing
CREATE OR REPLACE STAGE RAW.LANDING_STAGE
  STORAGE_INTEGRATION = aws_malaysia_islamic_finance_sukuk_S3_INT
  URL = 's3://sea-aws-demos-018437500440/aws-malaysia-islamic-finance-sukuk/';

-- ==================== KINESIS / IOT CORE INGESTION ====================
-- Snowpipe from Kinesis Data Stream
-- Stream ARN: arn:aws:kinesis:ap-southeast-1:018437500440:stream/aws-malaysia-islamic-finance-sukuk-stream

CREATE OR REPLACE PIPE RAW.REALTIME_PIPE
  AUTO_INGEST = TRUE
  INTEGRATION = 'aws_malaysia_islamic_finance_sukuk_S3_INT'
  COMMENT = 'Auto-ingest from Kinesis via S3 delivery stream'
AS
COPY INTO RAW.SUKUK_HOLDINGS
FROM @RAW.LANDING_STAGE/realtime/
FILE_FORMAT = (TYPE = 'JSON');

