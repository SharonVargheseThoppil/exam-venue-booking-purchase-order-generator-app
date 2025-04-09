from flask import Flask, request, jsonify, Blueprint
from flask_cors import CORS
import mysql.connector

# MySQL database configuration
db_config = {
    'user': 'sharon1234',
    'password': 'shar12',
    'host': 'localhost',
    'database': 'evb'
}

# Create Flask app instance
app = Flask(__name__)

# Blueprint for login routes
login_blueprint = Blueprint('login', __name__)
CORS(login_blueprint)  # Optionally, enable CORS specifically for this blueprint

# Function to get MySQL connection
def get_db_connection():
    return mysql.connector.connect(**db_config)

# Endpoint for user login
@login_blueprint.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')

    if not username or not password:
        return jsonify({'message': 'Missing username or password', 'status': 'error'}), 400

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        # Fetch the user from the database by username
        cursor.execute("SELECT * FROM users WHERE username = %s AND password = %s", (username, password))
        user = cursor.fetchone()
    except mysql.connector.Error as err:
        return jsonify({'message': f"Database error: {err}", 'status': 'error'}), 500
    finally:
        cursor.close()
        conn.close()

    # If user exists, return success response
    if user:
        return jsonify({
            'message': 'Login successful!',
            'status': 'success',
            'username': user['username'],
            'email': user['email']  # Send email as well
        }), 200
    else:
        return jsonify({'message': 'Invalid username or password', 'status': 'error'}), 401

# Initialize users table (storing plain-text passwords)
def create_users_table():
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INT AUTO_INCREMENT PRIMARY KEY,
            username VARCHAR(100) NOT NULL,
            password VARCHAR(100) NOT NULL,
            email VARCHAR(100) NOT NULL UNIQUE
        )
    """)
    conn.commit()
    cursor.close()
    conn.close()

# Register blueprint with the Flask app
app.register_blueprint(login_blueprint)

# Enable CORS for the whole app
CORS(app)

# Run the app
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
