from flask import Flask, request, jsonify
from flask_cors import CORS
import logging
import requests
import json

# Set up logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

app = Flask(__name__)
# Configure CORS to be more permissive
CORS(app, resources={r"/*": {"origins": "*"}})

OPENROUTER_API_KEY = "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"

@app.route('/', methods=['GET'])
def home():
    logger.debug("Home endpoint called")
    return jsonify({'status': 'ok'}), 200

@app.route('/chat', methods=['GET', 'POST'])
def chat():
    logger.debug("Chat endpoint called")
    if request.method == 'GET':
        return jsonify({"status": "ok"})
    
    try:
        data = request.get_json()
        context = data.get('context', '')
        question = data.get('question', '')
        
        # Simple response logic based on the context and question
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
        
        return jsonify({'response': response})
    except Exception as e:
        logger.error(f"Error in chat: {str(e)}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    logger.info("Starting server...")
    # Allow connections from any IP on the network
    app.run(debug=True, host='0.0.0.0', port=5000, threaded=True) 