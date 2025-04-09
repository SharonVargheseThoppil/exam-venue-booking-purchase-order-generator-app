from flask import Flask, jsonify, Blueprint, send_file
from flask_cors import CORS
import os
from datetime import datetime

# Define Flask app
app = Flask(__name__)
CORS(app)

# Define blueprint
send_po_pdf = Blueprint('send_po_pdf', __name__)

@send_po_pdf.route('/fetch_generated_pdfs', methods=['GET'])
def fetch_generated_pdfs():
    """Fetch list of generated PO PDFs."""
    pdf_dir = 'generated_pdfs'
    pdfs = []

    if not os.path.exists(pdf_dir):
        os.makedirs(pdf_dir)  # Create directory if it doesn't exist

    for filename in os.listdir(pdf_dir):
        if filename.endswith('.pdf'):
            file_path = os.path.join(pdf_dir, filename)
            generated_date = datetime.fromtimestamp(os.path.getctime(file_path)).strftime('%Y-%m-%d %H:%M:%S')
            pdfs.append({
                'filename': filename,
                'pdf_url': f' http://192.168.39.81:5001/send_po_pdf/get_pdf/{filename}',
                'generated_date': generated_date,
            })

    return jsonify(pdfs)

@send_po_pdf.route('/get_pdf/<filename>', methods=['GET'])
def get_pdf(filename):
    """Serve the generated PDF file."""
    pdf_path = os.path.join('generated_pdfs', filename)
    if os.path.exists(pdf_path):
        return send_file(pdf_path, as_attachment=True)
    return jsonify({'error': 'File not found'}), 404

# Register blueprint
app.register_blueprint(send_po_pdf, url_prefix='/send_po_pdf')

if __name__ == '__main__':
     app.run(host='0.0.0.0', port=5001, debug=True)