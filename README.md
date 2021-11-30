# AWS S3 for ABAP

ABAP wrapper around AWS S3 REST API.

## Dependencies
You'll need the following library in your ABAP platform to use AWS S3 for ABAP library:

+ [AWS Signature V4 for ABAP](https://github.com/tmhew/abap-aws-sigv4)

## Supported S3 Actions

These are highly opinionated wrappers around the respective S3 actions and by no mean meant to be comprehensive. If you have use cases that are not covered by these wrappers, consider implementing your own wrappers by making use of [AWS Signature V4 for ABAP](https://github.com/tmhew/abap-aws-sigv4).

| S3 Action | ABAP Object |
|-----------|-------------|
| [PutObject](https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObject.html) | [ZAWS_S3_PUT_OBJECT](https://github.com/tmhew/abap-aws-s3/blob/main/src/zaws_s3_put_object.clas.abap) |
| [ListBuckets](https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListBuckets.html) | [ZAWS_S3_LIST_BUCKETS](https://github.com/tmhew/abap-aws-s3/blob/main/src/zaws_s3_list_buckets.clas.abap) |

## References

+ [Amazon S3 endpoints and quotas](https://docs.aws.amazon.com/general/latest/gr/s3.html)
+ [AWS S3 Authenticating Requests (AWS Signature Version 4)](https://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-authenticating-requests.html)
