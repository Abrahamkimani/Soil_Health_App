import requests
import json
import logging

# Configure logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# OpenRouter API configuration
OPENROUTER_API_KEY = "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"
API_URL = "https://openrouter.ai/api/v1/chat/completions"

def test_openrouter_api():
    print("\n=== Testing OpenRouter API Connection ===")
    print(f"API Key: {OPENROUTER_API_KEY[:10]}...")
    print(f"API URL: {API_URL}\n")

    headers = {
        "Authorization": f"Bearer {OPENROUTER_API_KEY}",
        "Content-Type": "application/json",
        "HTTP-Referer": "http://localhost:5000"
    }

    # Only try the free model
    models = [
        "deepseek/deepseek-r1-0528:free"
    ]

    for model in models:
        print(f"\nTrying model: {model}")
        payload = {
            "model": model,
            "messages": [
                {
                    "role": "user",
                    "content": "Hello, this is a test message."
                }
            ],
            "temperature": 0.7,
            "max_tokens": 50
        }

        print("\nRequest Headers:", json.dumps(headers, indent=2))
        print("\nRequest Payload:", json.dumps(payload, indent=2))
        print("\nSending test request to OpenRouter API...")

        try:
            response = requests.post(API_URL, headers=headers, json=payload)
            print(f"\nResponse Status: {response.status_code}")
            print("Response Headers:", dict(response.headers))
            
            try:
                response_body = response.json()
                print("Response Body:", json.dumps(response_body, indent=2))
            except json.JSONDecodeError:
                print("Response Body (raw):", response.text)

            if response.status_code == 200:
                print(f"\n✅ Successfully connected to OpenRouter API using model: {model}")
                return True
            else:
                print(f"\n❌ Failed with model {model}: {response.status_code}")
                if response.status_code == 403:
                    print("Please check your API key at https://openrouter.ai/settings/keys")
                continue

        except Exception as e:
            print(f"\n❌ Error testing model {model}: {str(e)}")
            continue

    print("\n❌ All models failed. Please check your API key and try again.")
    return False

if __name__ == "__main__":
    print("Starting API test...")
    test_openrouter_api() 