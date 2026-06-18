# Validation Framework
from pydantic import BaseModel, Field

class S3Properties(BaseModel):
    aws_region: str = Field(..., alias="aws-region")
    acl: str
    bucket_name: str = Field(..., alias="bucket-name")

    class Config:
        populate_by_name = True

class RequestPayload(BaseModel):
    properties: S3Properties

class ConfigurationRequest(BaseModel):
    payload: RequestPayload