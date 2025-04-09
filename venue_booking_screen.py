from flask import Flask, Blueprint, request, jsonify, session
import pymysql
from flask_cors import CORS

app = Flask(__name__)
app.secret_key = 'your_secret_key'  # Make sure to use a strong secret key

# MySQL connection settings
app.config['MYSQL_HOST'] = 'localhost'
app.config['MYSQL_USER'] = 'sharon1234'
app.config['MYSQL_PASSWORD'] = 'shar12'
app.config['MYSQL_DB'] = 'evb'

# Establish MySQL connection
def get_db_connection():
    try:
        connection = pymysql.connect(
            host=app.config['MYSQL_HOST'],
            user=app.config['MYSQL_USER'],
            password=app.config['MYSQL_PASSWORD'],
            db=app.config['MYSQL_DB']
        )
        return connection
    except pymysql.MySQLError as e:
        print(f"Error while connecting to the database: {e}")
        return None

# Blueprint for venue booking routes
venue_booking_bp = Blueprint('venue_booking', __name__)
CORS(venue_booking_bp)

# Create tables if they don't exist
def create_tables():
    connection = get_db_connection()
    if connection:
        cursor = connection.cursor()
        cursor.execute(""" 
        CREATE TABLE IF NOT EXISTS venues (
            id INT AUTO_INCREMENT PRIMARY KEY,
            venue_name VARCHAR(255) NOT NULL,
            location VARCHAR(255) NOT NULL,
            address VARCHAR(255) NOT NULL
        );
        """)
        cursor.execute(""" 
        CREATE TABLE IF NOT EXISTS booked_venues (
            id INT AUTO_INCREMENT PRIMARY KEY,
            venue_name VARCHAR(255),
            location VARCHAR(255),
            address VARCHAR(255),
            status VARCHAR(50),
            username VARCHAR(255) NOT NULL
        );
        """)
        connection.commit()
        connection.close()

# Route to fetch all available venue details
@venue_booking_bp.route('/api/venues', methods=['GET'])
def get_venues():
    connection = get_db_connection()
    if connection:
        cursor = connection.cursor()
        cursor.execute("SELECT id, venue_name, location, address FROM venues")
        venues = cursor.fetchall()
        connection.close()

        return jsonify([{
            'id': venue[0],
            'venue_name': venue[1],
            'location': venue[2],
            'address': venue[3]
        } for venue in venues])
    
    return jsonify({'status': 'error', 'message': 'Database connection error'}), 500

# Route to add a new venue
@venue_booking_bp.route('/api/venues', methods=['POST'])
def add_venue():
    data = request.get_json()
    venue_name = data.get('venue_name')
    location = data.get('location')
    address = data.get('address')

    if not venue_name or not location or not address:
        return jsonify({'status': 'error', 'message': 'Missing required fields'}), 400

    connection = get_db_connection()
    if connection:
        cursor = connection.cursor()
        cursor.execute("INSERT INTO venues (venue_name, location, address) VALUES (%s, %s, %s)", 
                       (venue_name, location, address))
        connection.commit()
        connection.close()

        return jsonify({'status': 'success', 'message': 'Venue added successfully'}), 201
    
    return jsonify({'status': 'error', 'message': 'Database connection error'}), 500

# Route to confirm venue bookings (updated version with username from request)
@venue_booking_bp.route('/api/confirm_bookings', methods=['POST'])
def confirm_bookings():
    data = request.get_json()
    booked_venues = data.get('booked_venues')
    username = data.get('username')  # Get username from request

    if not username:
        return jsonify({'status': 'error', 'message': 'User not authenticated'}), 401

    if not booked_venues:
        return jsonify({'status': 'error', 'message': 'Missing booked venues'}), 400

    connection = get_db_connection()
    if connection:
        cursor = connection.cursor()
        for venue in booked_venues:
            venue_name = venue['venue_name']
            location = venue['location']
            address = venue['address']
            cursor.execute("INSERT INTO booked_venues (venue_name, location, address, status, username) VALUES (%s, %s, %s, %s, %s)", 
                           (venue_name, location, address, 'booked', username))
        connection.commit()
        connection.close()

        return jsonify({'status': 'success', 'message': 'Bookings confirmed'})

    return jsonify({'status': 'error', 'message': 'Database connection error'}), 500

# Route to remove a venue from bookings
@venue_booking_bp.route('/api/remove_booked_venue', methods=['POST'])
def remove_booked_venue():
    data = request.get_json()
    venue_name = data.get('venue_name')
    location = data.get('location')
    address = data.get('address')
    username = data.get('username')

    if not venue_name or not location or not address or not username:
        return jsonify({'status': 'error', 'message': 'Missing required fields'}), 400

    connection = get_db_connection()
    if connection:
        cursor = connection.cursor()
        cursor.execute("DELETE FROM booked_venues WHERE venue_name=%s AND location=%s AND address=%s AND username=%s", 
                       (venue_name, location, address, username))
        connection.commit()
        connection.close()

        return jsonify({'status': 'success', 'message': 'Venue removed from bookings'})
    
    return jsonify({'status': 'error', 'message': 'Database connection error'}), 500

# Register blueprint and initialize the app
app.register_blueprint(venue_booking_bp)
create_tables()

if __name__ == '__main__':
     app.run(host='0.0.0.0', port=5001, debug=True)
