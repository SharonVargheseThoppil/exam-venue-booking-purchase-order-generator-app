from flask import Flask, request, jsonify, Blueprint, send_file, g, send_from_directory
import mysql.connector
from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas
from reportlab.lib import colors
from reportlab.platypus import Table, TableStyle
import os
import logging
from flask_cors import CORS
import urllib.parse
from datetime import datetime

# Initialize Flask app
app = Flask(__name__)

# Setup CORS to allow requests from any origin
CORS(app)

# Setup logging
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')

# Define blueprint
po_pdf = Blueprint('po_pdf', __name__)
CORS(po_pdf)

# MySQL Database connection settings
db_config = {
    'host': 'localhost',
    'user': 'sharon1234',
    'password': 'shar12',
    'database': 'evb'
}

def get_db_connection():
    """Establish and return a database connection."""
    try:
        return mysql.connector.connect(**db_config)
    except mysql.connector.Error as e:
        logging.error(f"Database connection error: {str(e)}")
        return None

@app.teardown_appcontext
def close_db(error):
    """Close database connection after request."""
    db = g.pop('db', None)
    if db is not None:
        db.close()

def is_authenticated_user(username):
    """Check if the user is authenticated."""
    return bool(username)

# Helper function to draw multiline text on PDF
def draw_multiline_text(canvas_obj, text, x, y, max_width=500):
    """Draw multiline text on the canvas object."""
    text_object = canvas_obj.beginText(x, y)
    text_object.setFont("Helvetica", 12)
    text_object.setTextOrigin(x, y)
    for line in text.split('\n'):
        text_object.textLine(line)
    canvas_obj.drawText(text_object)

@po_pdf.route('/generate_po_pdf', methods=['POST'])
def generate_po_pdf():
    """Generate a purchase order PDF."""
    data = request.json
    if not data:
        logging.error('No JSON data received')
        return jsonify({'error': 'No JSON data received'}), 400

    venue_name = data.get('venue_name')
    exam_date = data.get('exam_date')
    username = data.get('username')

    if not venue_name or not exam_date or not username:
        logging.error('Missing venue name, exam date, or username')
        return jsonify({'error': 'Venue name, exam date, and username are required'}), 400

    if not is_authenticated_user(username):
        logging.error('User is not authenticated')
        return jsonify({'error': 'User authentication failed'}), 401

    # Validate exam_date format (YYYY-MM-DD)
    try:
        datetime.strptime(exam_date, '%Y-%m-%d')
    except ValueError:
        logging.error(f"Invalid exam_date format: {exam_date}")
        return jsonify({'error': 'Invalid exam_date format. Expected YYYY-MM-DD'}), 400

    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        if conn is None:
            raise Exception("Database connection failed")

        cursor = conn.cursor(dictionary=True)

        # Fetch venue details from the venues table
        cursor.execute("SELECT venue_name, address, location FROM venues WHERE venue_name = %s", (venue_name,))
        venue_details = cursor.fetchone()
        
        if not venue_details:
            logging.error(f"Venue not found: {venue_name}")
            return jsonify({'error': 'Venue not found'}), 404

        # Fetch purchase order details from submit_po_form
        cursor.execute("SELECT * FROM submit_po_form WHERE venue_name = %s AND exam_date = %s AND username = %s", (venue_name, exam_date, username))
        po_details = cursor.fetchone()

        if not po_details:
            logging.error(f"Purchase order not found for {venue_name} on {exam_date} and {username}")
            return jsonify({'error': 'Purchase order not found for this venue and exam date'}), 404

        # Calculate total expenses
        total_expenses = po_details['seats_morning'] * 100 + po_details['seats_afternoon'] * 100

        # Create PDF directory if it doesn't exist
        pdf_dir = r'D:\evb\generated_pdfs'
        os.makedirs(pdf_dir, exist_ok=True)
        pdf_file_name = f"PO_{venue_name}_{exam_date.replace('/', '_')}.pdf"
        pdf_path = os.path.join(pdf_dir, pdf_file_name)

        # Create PDF
        c = canvas.Canvas(pdf_path, pagesize=letter)
        c.setFont("Helvetica-Bold", 16)
        c.drawString(50, 800, "Purchase Order Details")

        from_address = "From:\nXYZ\nDelhi"
        to_address = f"To:\n{venue_details['venue_name']}\n{venue_details['address']},\n{venue_details['location']}"
        draw_multiline_text(c, from_address, 50, 750)
        draw_multiline_text(c, to_address, 350, 750)

        # Prepare table data
        table_data = [
            ["Field", "Details"],
            ["Venue Name", po_details['venue_name']],
            ["Exam Date", po_details['exam_date']],
            ["Exam Name", po_details['exam_name']],
            ["Seats Morning", po_details['seats_morning']],
            ["Seats Afternoon", po_details['seats_afternoon']],
            ["Total Candidates", po_details['total_candidates']],
            ["Invigilators", po_details['invigilators']],
            ["IT Admins", po_details['it_admins']],
            ["Security Guards", po_details['security_guards']],
            ["Electricians", po_details['electricians']],
            ["Network Admins", po_details['network_admins']],
            ["Total Expenses", f"Rs {total_expenses}"]
        ]

        # Draw table
        table = Table(table_data, colWidths=[100, 200])
        table.setStyle(TableStyle([ 
            ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('GRID', (0, 0), (-1, -1), 0.5, colors.black)
        ]))

        table.wrapOn(c, 50, 400)
        table.drawOn(c, 50, 400)
        c.save()

        # Store generated PDF in database
        cursor.execute(
            "INSERT INTO generated_pdfs (pdf_name, venue_name, exam_date, created_at, username) VALUES (%s, %s, %s, NOW(), %s)", 
            (pdf_file_name, venue_name, exam_date, username)
        )
        conn.commit()

        return jsonify({"message": "PDF generated successfully", "pdf_url": f"/po_pdf/download_po_pdf?pdf_file={urllib.parse.quote(pdf_file_name)}"}), 200

    except Exception as e:
        logging.error(f"Unexpected error in generate_po_pdf: {str(e)}")
        return jsonify({"error": f"Unexpected error: {str(e)}"}), 500
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

@po_pdf.route('/fetch_venues', methods=['GET'])
def fetch_venues():
    """Fetch purchase order details for a specific username and venue."""
    username = request.args.get('username')

    if not username or not is_authenticated_user(username):
        return jsonify({'error': 'Username and authentication are required'}), 400

    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        if conn is None:
            raise Exception("Database connection failed")

        cursor = conn.cursor(dictionary=True)
        
        # Fetch venue names and exam dates from submit_po_form table
        cursor.execute("SELECT venue_name, exam_date FROM submit_po_form WHERE username = %s", (username,))
        venues = cursor.fetchall()

        if venues:
            return jsonify({'venues': venues}), 200
        else:
            return jsonify({'error': 'No venues found'}), 404

    except Exception as e:
        logging.error(f"Error fetching venues: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

@po_pdf.route('/download_po_pdf', methods=['GET'])
def download_pdf():
    """Download the generated PDF using query parameter."""
    pdf_filename = request.args.get('pdf_file')

    if not pdf_filename:
        return jsonify({'error': 'No filename provided'}), 400

    # Decode spaces (%20) and other URL-encoded characters
    pdf_filename = urllib.parse.unquote(pdf_filename)

    # Define the directory where PDFs are stored
    pdf_dir = r'D:\evb\generated_pdfs'

    # Construct the full file path
    full_file_path = os.path.join(pdf_dir, pdf_filename)

    # Debug: Print the file path being checked
    print(f"Checking file: {full_file_path}")

    # Check if the file exists
    if os.path.exists(full_file_path):
        print(f"File found: {full_file_path}")
        return send_from_directory(pdf_dir, pdf_filename, as_attachment=True)
    else:
        print(f"File not found: {full_file_path}")
        return jsonify({'error': 'File not found'}), 404

# Register blueprint with URL prefix
app.register_blueprint(po_pdf, url_prefix='/po_pdf')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)