from flask import Flask, Blueprint, request, jsonify,session
import os
from flask import Flask
from flask_cors import CORS

app = Flask(__name__)
frontend_url = os.getenv('FRONTEND_URL', 'http://192.168.39.81:5001')
CORS(app, resources={r"/*": {"origins": frontend_url}})
# Initialize the Flask application


# Create a Blueprint for settings
settings_bp = Blueprint('settings', __name__, url_prefix='/api/settings')

def update_settings():
    if not session.get('logged_in'):
        return jsonify({"message": "Unauthorized"}), 401

# Sample settings data
settings = {
    
    "contact": {
        "email": "evb@gmail.com",
        "phone": "+1 234 567 890"
    },
    "terms": "These are the terms and privacy policy of the app."
}


@settings_bp.route('', methods=['GET'])
def get_settings():
    """Fetch current settings."""
    return jsonify(settings)




@settings_bp.route('/logout', methods=['POST'])
def logout():
    """Handle user logout."""
    return jsonify({"message": "User logged out successfully"})


# Register the Blueprint with the main app
app.register_blueprint(settings_bp)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)