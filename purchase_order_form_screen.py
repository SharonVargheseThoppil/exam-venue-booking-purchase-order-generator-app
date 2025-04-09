from flask import Flask, Blueprint, request, jsonify
import pymysql
from flask_cors import CORS

app = Flask(__name__)

# MySQL configuration
app.config['MYSQL_HOST'] = 'localhost'
app.config['MYSQL_USER'] = 'sharon1234'
app.config['MYSQL_PASSWORD'] = 'shar12'
app.config['MYSQL_DB'] = 'evb'

# Initialize Blueprint
purchase_order_form_screen_bp = Blueprint('purchase_order_form_screen', __name__)
CORS(purchase_order_form_screen_bp)

# Establish a connection to the MySQL database
def get_db_connection():
    try:
        conn = pymysql.connect(
            host=app.config['MYSQL_HOST'],
            user=app.config['MYSQL_USER'],
            password=app.config['MYSQL_PASSWORD'],
            db=app.config['MYSQL_DB'],
            cursorclass=pymysql.cursors.DictCursor
        )
        return conn
    except pymysql.MySQLError as e:
        print(f"Error connecting to database: {e}")
        return None

# Fetch booked venues
@purchase_order_form_screen_bp.route('/api/booked_venues', methods=['GET'])
def get_booked_venues():
    conn = get_db_connection()
    if conn is None:
        return jsonify({"error": "Database connection failed."}), 500

    try:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM booked_venues")
        venues = cursor.fetchall()
        return jsonify(venues)
    except pymysql.MySQLError as e:
        return jsonify({"error": f"Failed to fetch venues: {e}"}), 500
    finally:
        conn.close()

# Submit PO form
@purchase_order_form_screen_bp.route('/api/submit_po_form', methods=['POST'])
def submit_po_form():
    data = request.json

    try:
        # Getting the username from the request data (this should be passed when submitting the form)
        username = data['username']
        exam_date = data['exam_date']
        exam_name = data['exam_name']
        venue_name = data['venue_name']
        seats_morning = int(data['morning_seats'])
        seats_afternoon = int(data['afternoon_seats'])
        it_admins = int(data['no_of_it_admins'])
        security_guards = int(data['no_of_security_guards'])
        electricians = int(data['no_of_electricians'])
        network_admins = int(data['no_of_network_admins'])
        invigilator_count = data['invigilator_count']
        total_expenses = data['total_expenses']

        conn = get_db_connection()
        if conn is None:
            return jsonify({"error": "Database connection failed."}), 500

        cursor = conn.cursor()

        # Check if the venue is already booked for the selected date
        cursor.execute("""
            SELECT COUNT(*) FROM submit_po_form 
            WHERE exam_date = %s AND venue_name = %s
        """, (exam_date, venue_name))

        result = cursor.fetchone()
        if result['COUNT(*)'] > 0:
            return jsonify({"error": "This venue is already booked for the selected date."}), 400

        # Proceed to insert the booking if no existing booking found
        cursor.execute("""
            INSERT INTO submit_po_form (
                username, exam_date, exam_name, venue_name, seats_morning, 
                seats_afternoon, total_candidates, invigilators, it_admins, 
                security_guards, electricians, network_admins, total_expenses
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            username, exam_date, exam_name, venue_name, seats_morning, seats_afternoon,
            seats_morning + seats_afternoon, invigilator_count, it_admins, 
            security_guards, electricians, network_admins, total_expenses
        ))

        conn.commit()
        return jsonify({"message": "PO form submitted successfully!"}), 200
    except pymysql.MySQLError as e:
        return jsonify({"error": f"Database error: {e}"}), 500
    except Exception as e:
        return jsonify({"error": str(e)}), 400
    finally:
        conn.close()

# Register Blueprint
app.register_blueprint(purchase_order_form_screen_bp, url_prefix='/purchase_order')

if __name__ == '__main__':
     app.run(host='0.0.0.0', port=5001, debug=True)
