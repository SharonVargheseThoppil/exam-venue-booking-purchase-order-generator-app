from flask import Flask, session, redirect, url_for, request, jsonify
from flask_cors import CORS
from functools import wraps

# Import blueprints
from backend.login_screen import login_blueprint
from backend.register_screen import register_bp
from backend.venue_booking_screen import venue_booking_bp
from backend.purchase_order_form_screen import purchase_order_form_screen_bp
from backend.purchase_order_edit_screen import po_blueprint
from backend.purchase_order_pdf_generation_screen import po_pdf
from backend.send_po_gmail_screen import send_po_pdf

app = Flask(__name__)
app.secret_key = "your_secret_key"
CORS(app, supports_credentials=True)

# Middleware function to check authentication
def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'username' not in session:
            return jsonify({"message": "Unauthorized", "status": "error"}), 401
        return f(*args, **kwargs)
    return decorated_function

# Routes that require authentication
app.register_blueprint(login_blueprint)
app.register_blueprint(register_bp)
app.register_blueprint(venue_booking_bp, url_prefix='/venue_booking')
app.register_blueprint(purchase_order_form_screen_bp, url_prefix='/purchase_order')
app.register_blueprint(po_blueprint, url_prefix='/po')
app.register_blueprint(po_pdf, url_prefix='/po_pdf')
app.register_blueprint(send_po_pdf, url_prefix='/send_po_pdf')

@app.before_request
def protect_routes():
    """ Apply authentication restriction on specific routes """
    restricted_routes = [
        "/venue_booking", "/home", "/settings",
        "/purchase_order", "/po", "/po_pdf", "/send_po_pdf","/view_po"
    ]
    if request.path in restricted_routes and 'username' not in session:
        return jsonify({"message": "Unauthorized", "status": "error"}), 401

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)

