from flask import Flask, render_template, request, redirect, url_for, flash, session
from flask_cors import CORS
import firebase_admin
from firebase_admin import credentials, firestore, auth
from datetime import datetime, timedelta
from functools import wraps
import os
from werkzeug.security import check_password_hash, generate_password_hash

app = Flask(__name__)
app.secret_key = os.environ.get('SECRET_KEY', 'telemedicine-admin-secret-key-change-in-production')

# CORS
CORS(app)

# Initialize Firebase Admin
db = None
try:
    if not firebase_admin._apps:
        # Path to the service account key
        cred_path = os.path.join(os.path.dirname(__file__), 'serviceAccountKey.json')
        
        if not os.path.exists(cred_path):
            print("\n" + "="*80)
            print("⚠️  WARNING: Firebase Service Account Key Not Found!")
            print("="*80)
            print("\n📋 To download your Firebase Admin SDK service account key:\n")
            print("1. Go to: https://console.firebase.google.com/")
            print("2. Select your project")
            print("3. Click the ⚙️  Settings icon → Project settings")
            print("4. Go to the 'Service accounts' tab")
            print("5. Click 'Generate new private key' button")
            print("6. Save the downloaded JSON file as 'serviceAccountKey.json'")
            print("7. Move it to: " + os.path.dirname(__file__))
            print("\n" + "="*80)
            print("⚠️  Running in DEMO MODE without Firebase connection")
            print("="*80 + "\n")
            db = None
        else:
            # Verify the file is a valid service account key
            import json
            with open(cred_path, 'r') as f:
                service_data = json.load(f)
            
            if service_data.get('type') != 'service_account':
                print("\n❌ ERROR: The JSON file is not a valid service account key!")
                print("You have a 'google-services.json' (client config) but need a SERVICE ACCOUNT key.")
                print("Please follow the instructions above to download the correct file.\n")
                db = None
            else:
                cred = credentials.Certificate(cred_path)
                firebase_admin.initialize_app(cred)
                db = firestore.client()
                print("✅ Firebase Admin SDK initialized successfully!")
                
except Exception as e:
    print(f"\n❌ Error initializing Firebase: {str(e)}")
    print("Running in DEMO MODE without Firebase connection\n")
    db = None

# Admin credentials (in production, store these securely in environment variables)
ADMIN_CREDENTIALS = {
    'admin@telemedicine.com': generate_password_hash('admin123')  # Change this password in production!
}

# Login required decorator
def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'admin_email' not in session:
            flash('Please login to access this page', 'warning')
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function

# Template filter for safe date formatting
@app.template_filter('safe_strftime')
def safe_strftime(date_value, format='%b %d, %Y'):
    """Safely format a date/timestamp value"""
    if not date_value:
        return 'N/A'
    
    try:
        # If it's a Firestore timestamp, convert it
        if hasattr(date_value, 'timestamp'):
            date_value = datetime.fromtimestamp(date_value.timestamp())
        # If it's a string, parse it
        elif isinstance(date_value, str):
            date_value = datetime.fromisoformat(date_value.replace('Z', '+00:00'))
        # If it's already a datetime, use it
        elif isinstance(date_value, datetime):
            pass
        else:
            return 'N/A'
        
        return date_value.strftime(format)
    except Exception as e:
        return 'N/A'

# Helper functions
def get_stats():
    """Get dashboard statistics"""
    if db is None:
        # Return demo data when Firebase is not connected
        return {
            "total_doctors": 0,
            "total_patients": 0,
            "pending_verifications": 0,
            "approved_doctors": 0,
            "rejected_doctors": 0,
            "total_appointments": 0
        }
    
    try:
        doctors_ref = db.collection('doctors')
        users_ref = db.collection('users')
        
        all_doctors = list(doctors_ref.stream())
        total_doctors = len(all_doctors)
        
        pending_verifications = sum(1 for doc in all_doctors if doc.to_dict().get('verificationStatus') == 'pending')
        approved_doctors = sum(1 for doc in all_doctors if doc.to_dict().get('verificationStatus') == 'approved')
        rejected_doctors = sum(1 for doc in all_doctors if doc.to_dict().get('verificationStatus') == 'rejected')
        
        all_users = list(users_ref.stream())
        total_patients = sum(1 for doc in all_users if doc.to_dict().get('role') == 'patient')
        
        appointments_ref = db.collection('appointments')
        total_appointments = len(list(appointments_ref.stream()))
        
        return {
            "total_doctors": total_doctors,
            "total_patients": total_patients,
            "pending_verifications": pending_verifications,
            "approved_doctors": approved_doctors,
            "rejected_doctors": rejected_doctors,
            "total_appointments": total_appointments
        }
    except Exception as e:
        print(f"Error getting stats: {e}")
        return {
            "total_doctors": 0,
            "total_patients": 0,
            "pending_verifications": 0,
            "approved_doctors": 0,
            "rejected_doctors": 0,
            "total_appointments": 0
        }

# =================== Authentication Routes ===================

@app.route('/')
@login_required
def index():
    return redirect(url_for('dashboard'))

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        email = request.form.get('email')
        password = request.form.get('password')
        
        if email in ADMIN_CREDENTIALS and check_password_hash(ADMIN_CREDENTIALS[email], password):
            session['admin_email'] = email
            
            # Create admin document in Firestore if Firebase is connected
            if db is not None:
                try:
                    admin_id = email.replace('@', '_at_').replace('.', '_dot_')
                    admin_ref = db.collection('admins').document(admin_id)
                    if not admin_ref.get().exists:
                        admin_ref.set({
                            'email': email,
                            'createdAt': datetime.now(),
                            'lastLogin': datetime.now()
                        })
                    else:
                        admin_ref.update({'lastLogin': datetime.now()})
                except Exception as e:
                    print(f"Warning: Could not save admin login to Firebase: {e}")
            
            flash('Login successful!', 'success')
            return redirect(url_for('dashboard'))
        else:
            flash('Invalid email or password', 'danger')
    
    return render_template('login.html')

@app.route('/logout')
def logout():
    session.pop('admin_email', None)
    flash('Logged out successfully', 'success')
    return redirect(url_for('login'))

# =================== Dashboard Routes ===================

@app.route('/dashboard')
@login_required
def dashboard():
    stats = get_stats()
    # Add Firebase connection status
    firebase_connected = db is not None
    return render_template('dashboard.html', stats=stats, firebase_connected=firebase_connected)

# =================== Doctor Management Routes ===================

@app.route('/doctors')
@login_required
def doctors():
    try:
        # Verify Firebase connection
        if db is None:
            flash('Firebase not connected. Please check service account key.', 'warning')
            return render_template('doctors.html', doctors=[], stats=get_stats())
        
        status_filter = request.args.get('status', '')
        search_query = request.args.get('search', '')
        
        query = db.collection('doctors')
        
        if status_filter:
            query = query.where('verificationStatus', '==', status_filter)
        
        doctors_list = []
        for doc in query.stream():
            doctor_data = doc.to_dict()
            doctor_data['id'] = doc.id
            
            # Apply search filter
            if search_query:
                search_lower = search_query.lower()
                name_match = search_lower in doctor_data.get('name', '').lower()
                email_match = search_lower in doctor_data.get('email', '').lower()
                if not (name_match or email_match):
                    continue
            
            doctors_list.append(doctor_data)
        
        stats = get_stats()
        return render_template('doctors.html', doctors=doctors_list, stats=stats)
    except Exception as e:
        print(f'Error in doctors route: {str(e)}')
        import traceback
        traceback.print_exc()
        flash(f'Error loading doctors: {str(e)}', 'danger')
        return render_template('doctors.html', doctors=[], stats=get_stats())

@app.route('/doctors/<doctor_id>')
@login_required
def doctor_detail(doctor_id):
    if db is None:
        flash('Firebase not connected. Cannot load doctor details.', 'warning')
        return redirect(url_for('doctors'))
    
    try:
        doc = db.collection('doctors').document(doctor_id).get()
        if not doc.exists:
            flash('Doctor not found', 'danger')
            return redirect(url_for('doctors'))
        
        doctor_data = doc.to_dict()
        doctor_data['id'] = doc.id
        
        # Organize certificate URLs for easier template access
        doctor_data['certificateURLs'] = {
            'bmdc': doctor_data.get('bmdcCertificateURL'),
            'nid': doctor_data.get('nidURL'),
            'degree': doctor_data.get('degreeCertificateURL'),
            'specialist': doctor_data.get('specialistCertificateURL'),
        }
        
        # Organize workplace info
        doctor_data['workplaceInfo'] = {
            'hospital': doctor_data.get('workplaceHospital'),
            'department': doctor_data.get('workplaceDepartment'),
        }
        
        return render_template('doctor_detail.html', doctor=doctor_data)
    except Exception as e:
        flash(f'Error loading doctor details: {str(e)}', 'danger')
        return redirect(url_for('doctors'))

@app.route('/doctors/<doctor_id>/approve', methods=['POST'])
@login_required
def approve_doctor(doctor_id):
    if db is None:
        flash('Firebase not connected. Cannot approve doctor.', 'warning')
        return redirect(url_for('doctors'))
    
    try:
        # Update doctor verification status
        doctor_ref = db.collection('doctors').document(doctor_id)
        doctor_ref.update({
            'verificationStatus': 'approved',
            'approvedAt': datetime.now(),
            'rejectionReason': None,
            'updatedAt': datetime.now(),
            'active': True,
        })
        
        # Also update users collection
        user_ref = db.collection('users').document(doctor_id)
        if user_ref.get().exists:
            user_ref.update({
                'verificationStatus': 'approved',
                'updatedAt': datetime.now(),
            })
        
        flash('Doctor approved successfully!', 'success')
        
        # TODO: Send notification to doctor via email or FCM
        
    except Exception as e:
        flash(f'Error approving doctor: {str(e)}', 'danger')
    
    return redirect(url_for('doctor_detail', doctor_id=doctor_id))

@app.route('/doctors/<doctor_id>/reject', methods=['POST'])
@login_required
def reject_doctor(doctor_id):
    if db is None:
        flash('Firebase not connected. Cannot reject doctor.', 'warning')
        return redirect(url_for('doctors'))
    
    try:
        rejection_reason = request.form.get('rejection_reason')
        if not rejection_reason:
            flash('Rejection reason is required', 'danger')
            return redirect(url_for('doctor_detail', doctor_id=doctor_id))
        
        doctor_ref = db.collection('doctors').document(doctor_id)
        doctor_ref.update({
            'verificationStatus': 'rejected',
            'rejectionReason': rejection_reason,
            'approvedAt': None,
            'updatedAt': datetime.now()
        })
        flash('Doctor application rejected', 'success')
        
        # TODO: Send notification to doctor
        
    except Exception as e:
        flash(f'Error rejecting doctor: {str(e)}', 'danger')
    
    return redirect(url_for('doctor_detail', doctor_id=doctor_id))

@app.route('/doctors/<doctor_id>/restrict', methods=['POST'])
@login_required
def restrict_doctor(doctor_id):
    if db is None:
        flash('Firebase not connected. Cannot restrict doctor.', 'warning')
        return redirect(url_for('doctors'))
    
    try:
        doctor_ref = db.collection('doctors').document(doctor_id)
        doctor_ref.update({
            'isRestricted': True,
            'updatedAt': datetime.now()
        })
        
        # Also update in users collection
        user_ref = db.collection('users').document(doctor_id)
        if user_ref.get().exists:
            user_ref.update({'isRestricted': True, 'updatedAt': datetime.now()})
        
        flash('Doctor access restricted successfully', 'warning')
    except Exception as e:
        flash(f'Error restricting doctor: {str(e)}', 'danger')
    
    return redirect(url_for('doctor_detail', doctor_id=doctor_id))

@app.route('/doctors/<doctor_id>/delete', methods=['POST'])
@login_required
def delete_doctor(doctor_id):
    if db is None:
        flash('Firebase not connected. Cannot delete doctor.', 'warning')
        return redirect(url_for('doctors'))
    
    try:
        # Delete from Firestore
        db.collection('doctors').document(doctor_id).delete()
        db.collection('users').document(doctor_id).delete()
        
        # Delete from Firebase Auth
        try:
            auth.delete_user(doctor_id)
        except Exception as auth_error:
            print(f"Error deleting from Firebase Auth: {auth_error}")
        
        flash('Doctor deleted successfully', 'success')
        return redirect(url_for('doctors'))
    except Exception as e:
        flash(f'Error deleting doctor: {str(e)}', 'danger')
        return redirect(url_for('doctor_detail', doctor_id=doctor_id))

# =================== Patient Management Routes ===================

@app.route('/patients')
@login_required
def patients():
    try:
        # Verify Firebase connection
        if db is None:
            flash('Firebase not connected. Please check service account key.', 'warning')
            empty_stats = {'total': 0, 'active': 0, 'restricted': 0, 'new_this_month': 0}
            return render_template('patients.html', patients=[], stats=empty_stats, page=1, total_pages=1)
        
        search_query = request.args.get('search', '')
        status_filter = request.args.get('status', '')
        
        query = db.collection('users').where('role', '==', 'patient')
        
        patients_list = []
        for doc in query.stream():
            patient_data = doc.to_dict()
            patient_data['id'] = doc.id
            
            # Convert Firestore timestamps to datetime objects
            if 'createdAt' in patient_data and patient_data['createdAt']:
                if hasattr(patient_data['createdAt'], 'timestamp'):
                    # It's a Firestore timestamp object
                    patient_data['createdAt'] = patient_data['createdAt']
                elif isinstance(patient_data['createdAt'], str):
                    # It's a string, convert to datetime
                    try:
                        patient_data['createdAt'] = datetime.fromisoformat(patient_data['createdAt'].replace('Z', '+00:00'))
                    except:
                        patient_data['createdAt'] = None
            
            # Apply search filter
            if search_query:
                search_lower = search_query.lower()
                name_match = search_lower in patient_data.get('name', '').lower()
                email_match = search_lower in patient_data.get('email', '').lower()
                phone_match = search_lower in patient_data.get('phone', '').lower() if patient_data.get('phone') else False
                if not (name_match or email_match or phone_match):
                    continue
            
            # Apply status filter
            if status_filter == 'active' and patient_data.get('isRestricted'):
                continue
            if status_filter == 'restricted' and not patient_data.get('isRestricted'):
                continue
            
            patients_list.append(patient_data)
        
        # Calculate stats
        stats = {
            'total': len(patients_list),
            'active': sum(1 for p in patients_list if not p.get('isRestricted')),
            'restricted': sum(1 for p in patients_list if p.get('isRestricted')),
            'new_this_month': 0  # TODO: Calculate based on createdAt
        }
        
        return render_template('patients.html', 
                             patients=patients_list, 
                             stats=stats, 
                             page=1, 
                             total_pages=1)
    except Exception as e:
        flash(f'Error loading patients: {str(e)}', 'danger')
        empty_stats = {'total': 0, 'active': 0, 'restricted': 0, 'new_this_month': 0}
        return render_template('patients.html', 
                             patients=[], 
                             stats=empty_stats, 
                             page=1, 
                             total_pages=1)

@app.route('/patients/<patient_id>/restrict', methods=['POST'])
@login_required
def restrict_patient(patient_id):
    if db is None:
        flash('Firebase not connected. Cannot restrict patient.', 'warning')
        return redirect(url_for('patients'))
    
    try:
        user_ref = db.collection('users').document(patient_id)
        user_ref.update({
            'isRestricted': True,
            'updatedAt': datetime.now()
        })
        flash('Patient access restricted successfully', 'warning')
    except Exception as e:
        flash(f'Error restricting patient: {str(e)}', 'danger')
    
    return redirect(url_for('patients'))

@app.route('/patients/<patient_id>/activate', methods=['POST'])
@login_required
def activate_patient(patient_id):
    if db is None:
        flash('Firebase not connected. Cannot activate patient.', 'warning')
        return redirect(url_for('patients'))
    
    try:
        user_ref = db.collection('users').document(patient_id)
        user_ref.update({
            'isRestricted': False,
            'updatedAt': datetime.now()
        })
        flash('Patient activated successfully', 'success')
    except Exception as e:
        flash(f'Error activating patient: {str(e)}', 'danger')
    
    return redirect(url_for('patients'))

@app.route('/patients/<patient_id>/delete', methods=['POST'])
@login_required
def delete_patient(patient_id):
    if db is None:
        flash('Firebase not connected. Cannot delete patient.', 'warning')
        return redirect(url_for('patients'))
    
    try:
        # Delete user document
        db.collection('users').document(patient_id).delete()
        
        # Delete from Firebase Auth
        try:
            auth.delete_user(patient_id)
        except Exception as auth_error:
            print(f"Error deleting from Firebase Auth: {auth_error}")
        
        flash('Patient deleted successfully', 'success')
    except Exception as e:
        flash(f'Error deleting patient: {str(e)}', 'danger')
    
    return redirect(url_for('patients'))

@app.route('/patients/<patient_id>')
@login_required
def patient_detail(patient_id):
    """Patient detail page - to be implemented"""
    if db is None:
        flash('Firebase not connected. Cannot load patient details.', 'warning')
        return redirect(url_for('patients'))
    
    try:
        doc = db.collection('users').document(patient_id).get()
        if not doc.exists:
            flash('Patient not found', 'danger')
            return redirect(url_for('patients'))
        
        patient_data = doc.to_dict()
        patient_data['id'] = doc.id
        
        # For now, redirect back to patients list
        # TODO: Create patient_detail.html template
        flash('Patient detail view not yet implemented', 'info')
        return redirect(url_for('patients'))
    except Exception as e:
        flash(f'Error loading patient details: {str(e)}', 'danger')
        return redirect(url_for('patients'))

# =================== Analytics Routes ===================

@app.route('/analytics')
@login_required
def analytics():
    try:
        stats = get_stats()
        
        # Analytics data
        analytics_data = {
            'total_users': stats['total_doctors'] + stats['total_patients'],
            'new_users_percent': 15,  # TODO: Calculate actual percentage
            'total_appointments': stats['total_appointments'],
            'appointments_this_month': 45,  # TODO: Calculate from Firestore
            'approved_doctors': stats['approved_doctors'],
            'pending_verifications': stats['pending_verifications'],
            'avg_response_time': 24  # Hours - TODO: Calculate actual
        }
        
        # Generate date ranges for charts
        dates_30 = [(datetime.now() - timedelta(days=i)).strftime('%Y-%m-%d') for i in range(30, 0, -1)]
        dates_15 = [(datetime.now() - timedelta(days=i)).strftime('%Y-%m-%d') for i in range(15, 0, -1)]
        
        # Chart data (using sample data - TODO: replace with real Firestore data)
        registration_data = {
            'dates': dates_30,
            'counts': [5, 8, 6, 12, 15, 10, 8, 14, 11, 9, 16, 13, 10, 12, 18, 15, 12, 14, 16, 13, 17, 15, 19, 14, 12, 16, 18, 20, 15, 17]
        }
        
        user_distribution = {
            'doctors': stats['total_doctors'],
            'patients': stats['total_patients']
        }
        
        appointments_data = {
            'dates': dates_15,
            'counts': [12, 15, 18, 14, 16, 20, 17, 15, 19, 21, 16, 18, 22, 19, 17]
        }
        
        verification_data = {
            'approved': stats['approved_doctors'],
            'pending': stats['pending_verifications'],
            'rejected': stats['rejected_doctors']
        }
        
        specializations_data = {
            'names': ['Cardiology', 'Dermatology', 'Neurology', 'Pediatrics', 'Psychiatry', 'General Medicine'],
            'counts': [45, 38, 32, 28, 25, 20]
        }
        
        # Recent activities - TODO: fetch from Firestore activity log
        recent_activities = [
            {'type': 'doctor_approved', 'title': 'Doctor Approved', 'description': 'Dr. Ahmed Khan verified', 'time': '2 hours ago'},
            {'type': 'new_signup', 'title': 'New Registration', 'description': 'Patient John Doe registered', 'time': '4 hours ago'},
        ]
        
        # Alerts
        alerts = []
        if stats['pending_verifications'] > 0:
            alerts.append({
                'type': 'warning', 
                'title': 'Pending Verifications', 
                'message': f'{stats["pending_verifications"]} doctor verification(s) awaiting review'
            })
        
        return render_template('analytics.html', 
                             analytics=analytics_data,
                             registration_data=registration_data,
                             user_distribution=user_distribution,
                             appointments_data=appointments_data,
                             verification_data=verification_data,
                             specializations_data=specializations_data,
                             recent_activities=recent_activities,
                             alerts=alerts)
    except Exception as e:
        flash(f'Error loading analytics: {str(e)}', 'danger')
        # Return with empty data
        return render_template('analytics.html', 
                             analytics={},
                             registration_data={'dates': [], 'counts': []},
                             user_distribution={'doctors': 0, 'patients': 0},
                             appointments_data={'dates': [], 'counts': []},
                             verification_data={'approved': 0, 'pending': 0, 'rejected': 0},
                             specializations_data={'names': [], 'counts': []},
                             recent_activities=[],
                             alerts=[])

# =================== Error Handlers ===================

@app.errorhandler(404)
def not_found(e):
    # Don't redirect if we're already trying to access the dashboard
    if 'login' in request.url:
        return render_template('login.html'), 404
    if session.get('admin_email'):
        return redirect(url_for('dashboard'))
    return redirect(url_for('login'))

@app.errorhandler(500)
def server_error(e):
    print(f'500 Error: {str(e)}')
    import traceback
    traceback.print_exc()
    flash(f'Server error: {str(e)}', 'danger')
    if session.get('admin_email'):
        return redirect(url_for('dashboard'))
    return redirect(url_for('login'))

# =================== Main ===================

if __name__ == "__main__":
    print("=" * 60)
    print("TeleMedicine Admin Dashboard")
    print("=" * 60)
    print("Starting Flask server...")
    print("Admin Dashboard: http://localhost:5000")
    print("Default Login: admin@telemedicine.com / admin123")
    print("=" * 60)
    app.run(debug=True, host="0.0.0.0", port=5000)
