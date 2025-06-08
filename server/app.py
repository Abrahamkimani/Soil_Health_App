from flask import Flask, request, jsonify
from flask_cors import CORS
import logging
import json
import requests
import traceback
import sys
import socket

# Simple logging setup
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

OPENROUTER_API_KEY = "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"
OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions"

def test_openrouter_connection():
    print("\n=== Testing OpenRouter API Connection ===")
    try:
        headers = {
            "Authorization": f"Bearer {OPENROUTER_API_KEY}",
            "Content-Type": "application/json",
            "HTTP-Referer": "http://localhost:5000",
        }
        
        payload = {
            "model": "deepseek/deepseek-r1-0528:free",
            "messages": [
                {"role": "user", "content": "Hello, this is a test message."}
            ],
            "temperature": 0.7,
            "max_tokens": 50
        }
        
        print("Sending test request to OpenRouter API...")
        response = requests.post(OPENROUTER_API_URL, headers=headers, json=payload, timeout=30)
        print(f"Test Response Status: {response.status_code}")
        print(f"Test Response Body: {response.text}")
        
        if response.status_code == 200:
            print("✅ OpenRouter API connection successful!")
            return True
        else:
            print(f"❌ OpenRouter API connection failed: {response.status_code} - {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ OpenRouter API connection error: {str(e)}")
        print(f"Traceback: {traceback.format_exc()}")
        return False

def call_openrouter_api(prompt, context, temperature=0.7, max_tokens=500):
    try:
        print("\n=== Starting OpenRouter API Call ===")
        print(f"API Key: {OPENROUTER_API_KEY[:10]}...")
        
        headers = {
            "Authorization": f"Bearer {OPENROUTER_API_KEY}",
            "Content-Type": "application/json",
            "HTTP-Referer": "http://localhost:5000",
        }
        
        system_prompt = """You are a helpful agricultural assistant specializing in soil science and plant nutrition. 
        Provide detailed, accurate information about soil parameters and their effects on plant growth. 
        Use scientific terminology when appropriate but explain concepts clearly.
        Always reference the current readings provided in the context to give relevant and actionable advice.
        Include specific recommendations based on the current readings to help the user improve their soil health.
        IMPORTANT: Always provide a complete response in the 'content' field, not just in the 'reasoning' field."""
        
        user_prompt = f"""Context: {context}
        Question: {prompt}
        Please provide a detailed, informative response that directly addresses the question and includes specific recommendations based on the current readings."""
        
        payload = {
            "model": "deepseek/deepseek-r1-0528:free",
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            "temperature": temperature,
            "max_tokens": max_tokens
        }
        
        print(f"\nAPI Request Headers: {json.dumps(headers, indent=2)}")
        print(f"\nAPI Request Payload: {json.dumps(payload, indent=2)}")
        
        print("\nSending request to OpenRouter API...")
        try:
            response = requests.post(OPENROUTER_API_URL, headers=headers, json=payload, timeout=30)
            print(f"\nAPI Response Status: {response.status_code}")
            print(f"API Response Headers: {dict(response.headers)}")
            print(f"API Response Body: {response.text}")
            
            if response.status_code == 200:
                response_data = response.json()
                print(f"\nParsed Response: {json.dumps(response_data, indent=2)}")
                
                # Get the content from the response
                content = response_data['choices'][0]['message'].get('content', '')
                
                # If content is empty but reasoning exists, use reasoning as fallback
                if not content and 'reasoning' in response_data['choices'][0]['message']:
                    content = response_data['choices'][0]['message']['reasoning']
                
                # If still empty, use a default response
                if not content:
                    content = "I apologize, but I'm having trouble generating a response. Please try asking your question again."
                
                return content
            else:
                error_msg = f"OpenRouter API error: {response.status_code} - {response.text}"
                print(f"\nError: {error_msg}")
                raise Exception(error_msg)
                
        except requests.exceptions.RequestException as e:
            print(f"\nRequest failed: {str(e)}")
            raise
            
    except Exception as e:
        print(f"\nError in OpenRouter API call: {str(e)}")
        print(f"Traceback: {traceback.format_exc()}")
        raise

@app.route('/chat', methods=['GET', 'POST'])
def chat():
    print("\n=== Chat Endpoint Called ===")
    print(f"Request method: {request.method}")
    print(f"Request headers: {dict(request.headers)}")
    print(f"Request remote address: {request.remote_addr}")
    print(f"Request URL: {request.url}")
    
    if request.method == 'GET':
        print("Handling GET request")
        return jsonify({"status": "ok"})
    
    try:
        # Log raw request data
        raw_data = request.get_data()
        print(f"\nRaw request data: {raw_data}")
        
        data = request.get_json()
        print(f"\nParsed JSON data: {json.dumps(data, indent=2)}")
        
        if not data:
            print("No JSON data received")
            return jsonify({"error": "No data received"}), 400
            
        context = data.get('context', '')
        question = data.get('question', '')
        
        if not question:
            print("No question provided")
            return jsonify({"error": "No question provided"}), 400
        
        print(f"\nProcessing question: {question}")
        print(f"Context: {context}")
        
        try:
            # Try to get AI response
            print("\nAttempting to get AI response...")
            ai_response = call_openrouter_api(
                prompt=question,
                context=context,
                temperature=data.get('temperature', 0.7),
                max_tokens=data.get('max_length', 200)
            )
            print(f"\nSuccessfully got AI response: {ai_response}")
            
            # Log the response being sent back
            response_data = {'response': ai_response}
            print(f"\nSending response: {json.dumps(response_data, indent=2)}")
            return jsonify(response_data)
            
        except Exception as api_error:
            print(f"\nError getting AI response: {str(api_error)}")
            print(f"Traceback: {traceback.format_exc()}")
            # Fallback to simple response if AI fails
            response = f"Based on your question about {context}, here's what I can tell you: "
            
            if "nitrogen" in context.lower():
                response += "Nitrogen is essential for plant growth and leaf development. "
            elif "phosphorus" in context.lower():
                response += "Phosphorus is crucial for root development and flowering. "
            elif "potassium" in context.lower():
                response += "Potassium helps with overall plant health and disease resistance. "
            elif "ph" in context.lower():
                response += "Soil pH affects nutrient availability to plants. "
            
            response += "Would you like to know more specific details about this parameter?"
            
            print(f"\nUsing fallback response: {response}")
            return jsonify({'response': response})
        
    except Exception as e:
        print(f"\nError in chat endpoint: {str(e)}")
        print(f"Traceback: {traceback.format_exc()}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    print("\n=== Starting Server ===")
    print("OpenRouter API Key:", OPENROUTER_API_KEY[:10] + "...")
    print("OpenRouter API URL:", OPENROUTER_API_URL)
    
    # Test the OpenRouter API connection
    if not test_openrouter_connection():
        print("\n⚠️ Warning: OpenRouter API connection test failed!")
        print("The server will start but may not be able to process AI requests.")
    
    # Get all available network interfaces
    hostname = socket.gethostname()
    local_ip = socket.gethostbyname(hostname)
    print(f"\nServer will be available at:")
    print(f"- Local: http://localhost:5000")
    print(f"- Network: http://{local_ip}:5000")
    print(f"- All interfaces: http://0.0.0.0:5000")
    
    app.run(debug=True, host='0.0.0.0', port=5000) 