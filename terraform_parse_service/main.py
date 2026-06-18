import os
from io import BytesIO
from flask import Flask, request, jsonify, send_file
from pydantic import ValidationError
from models import ConfigurationRequest
from generator import TerraformGenerator

app = Flask(__name__)

@app.route('/generate-bucket-config', methods=['POST'])
def generate_terraform():
    try:
        # Validate incoming JSON against our Pydantic model
        user_input = request.get_json()
        validated_data = ConfigurationRequest.model_validate(user_input)
        
        # Extract fields cleanly from validated object
        props = validated_data.payload.properties
        
        # Generate the configuration
        tf_content = TerraformGenerator.generate_s3_config(
            aws_region=props.aws_region,
            bucket_name=props.bucket_name,
            acl=props.acl
        )
        
        tf_file = BytesIO(tf_content.encode("utf-8"))
        return send_file(
            tf_file,
            mimetype="application/octet-stream",
            as_attachment=True,
            download_name=f"{props.bucket_name}.tf"
        )

    except ValidationError as e:
        return jsonify({"error": "Validation failed", "details": e.errors()}), 400
    except Exception as e:
        return jsonify({"error": f"Internal server error: {str(e)}"}), 500

@app.route('/healthz', methods=['GET'])
def health_check():
    """Kubernetes liveness/readiness probe endpoint"""
    return jsonify({"status": "healthy"}), 200

if __name__ == '__main__':
    port = int(os.environ.get("PORT", 8080))
    app.run(host='0.0.0.0', port=port)
