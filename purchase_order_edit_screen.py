from flask import Flask, Blueprint, request, jsonify
from flask_cors import CORS
import mysql.connector
from datetime import datetime

app = Flask(__name__)

po_blueprint = Blueprint('po', __name__)
CORS(po_blueprint)

db_config = {
    'host': 'localhost',
    'user': 'sharon1234',
    'password': 'shar12',
    'database': 'evb',
}

def connect_db():
    try:
        conn = mysql.connector.connect(**db_config)
        return conn
    except mysql.connector.Error as e:
        print(f"Error connecting to MySQL: {e}")
        return None

def validate_date(date_str):
    try:
        corrected_date = datetime.strptime(date_str, "%Y-%m-%d").strftime("%Y-%m-%d")
        return corrected_date
    except ValueError:
        return None

@po_blueprint.route('/api/fetch_submit_po_form', methods=['GET'])
def fetch_submit_po_form():
    try:
        conn = connect_db()
        if conn is None:
            return jsonify({'error': 'Database connection failed'}), 500
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM submit_po_form")
        purchase_orders = cursor.fetchall()
        cursor.close()
        conn.close()
        return jsonify(purchase_orders)
    except Exception as e:
        print(f"Error fetching data: {e}")
        return jsonify({'error': 'Failed to fetch data'}), 500

@po_blueprint.route('/api/update_submit_po_form/<int:id>', methods=['PUT'])
def update_submit_po_form(id):
    try:
        if not request.is_json:
            return jsonify({'error': 'Invalid content type. Expected application/json'}), 400

        data = request.get_json()
        if not data:
            return jsonify({'error': 'Invalid or missing JSON data'}), 400

        required_fields = [
            'username', 'exam_date', 'exam_name', 'venue_name', 'seats_morning',
            'seats_afternoon', 'invigilators', 'it_admins', 'security_guards',
            'electricians', 'network_admins', 'total_expenses'
        ]

        for field in required_fields:
            if field not in data:
                return jsonify({'error': f'Missing field: {field}'}), 400

        exam_date = validate_date(data['exam_date'])
        if not exam_date:
            return jsonify({'error': 'Invalid date format. Use YYYY-MM-DD'}), 400

        # Calculate total candidates if not provided
        if not data.get('total_candidates'):
            data['total_candidates'] = data['seats_morning'] + data['seats_afternoon']

        conn = connect_db()
        if conn is None:
            return jsonify({'error': 'Database connection failed'}), 500
        cursor = conn.cursor()

        query = """
            UPDATE submit_po_form
            SET username = %s, exam_date = %s, exam_name = %s, venue_name = %s,
                seats_morning = %s, seats_afternoon = %s, total_candidates = %s,
                invigilators = %s, it_admins = %s, security_guards = %s,
                electricians = %s, network_admins = %s, total_expenses = %s
            WHERE id = %s
        """
        values = (
            data['username'], exam_date, data['exam_name'],
            data['venue_name'], data['seats_morning'], data['seats_afternoon'],
            data['total_candidates'], data['invigilators'], data['it_admins'],
            data['security_guards'], data['electricians'], data['network_admins'],
            data['total_expenses'], id
        )

        cursor.execute(query, values)
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({'message': 'Purchase Order updated successfully'}), 200

    except Exception as e:
        print(f"Error updating data: {e}")
        return jsonify({'error': 'Failed to update data'}), 500

app.register_blueprint(po_blueprint, url_prefix='/po')
CORS(app)
if __name__ == '__main__':
     app.run(host='0.0.0.0', port=5001, debug=True)
