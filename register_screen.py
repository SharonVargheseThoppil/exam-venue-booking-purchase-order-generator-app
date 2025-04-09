from flask import Flask, Blueprint, request, jsonify
from flask_cors import CORS
import pymysql

# MySQL configuration
db_config = {
    'host': 'localhost',
    'user': 'sharon1234',
    'password': 'shar12',
    'database': 'evb'
}

# Create Flask app instance
app = Flask(__name__)

# Blueprint for registration routes
register_bp = Blueprint('register', __name__)
CORS(register_bp)  # Enable CORS for the blueprint

# Enable CORS for the entire Flask app
CORS(app)

# Function to create users table if not exists
def create_users_table():
    connection = pymysql.connect(**db_config)
    cursor = connection.cursor()
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        username VARCHAR(100) NOT NULL UNIQUE,
        email VARCHAR(100) NOT NULL UNIQUE,
        password VARCHAR(255) NOT NULL
    );
    """)
    connection.commit()
    connection.close()

# Route to handle user registration
@register_bp.route('/register', methods=['POST'])
def register_user():
    data = request.get_json()
    username = data.get('username')
    email = data.get('email')
    password = data.get('password')  # Storing password directly (Not Recommended)

    if not username or not email or not password:
        return jsonify({'status': 'error', 'message': 'Please provide username, email, and password'}), 400

    connection = pymysql.connect(**db_config)
    cursor = connection.cursor()
    cursor.execute("SELECT * FROM users WHERE username = %s OR email = %s", (username, email))
    existing_user = cursor.fetchone()

    if existing_user:
        connection.close()
        return jsonify({'status': 'error', 'message': 'Username or email already exists'}), 400

    # Store the password in plain text (Not Recommended)
    cursor.execute("INSERT INTO users (username, email, password) VALUES (%s, %s, %s)", 
                   (username, email, password))

    connection.commit()
    connection.close()

    return jsonify({'status': 'success', 'message': 'User registered successfully'}), 200

# Register blueprint with the Flask app
app.register_blueprint(register_bp)

# Initialize users table on startup
if __name__ == '__main__':
    create_users_table()  # Ensure the users table is created when the app starts
    app.run(debug=True, host='0.0.0.0', port=5001)  # Listen on all IP addresses and port 5000
