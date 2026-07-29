from flask import Flask, render_template, request, redirect, url_for, flash, session
from flask_cors import CORS
import firebase_admin
from firebase_admin import credentials, firestore, auth
from datetime import datetime, timedelta
from functools import wraps
import os
from werkzeug.security import check_password_hash, generate_password_hash

app = Flask(__name__)
app.secret_key = os.environ.get('SECRET_KEY', 'mediconnect-admin-secret-key-change-in-production')

# CORS
CORS(app)

# Initialize Firebase Admin
db = None
try:
    if not firebase_admin._apps:
        # Path to the service account key
        cred_path = os.path.join(os.path.dirname(__file__), 'serviceAccountKey.json')
        env_cred_json = os.environ.get('FIREBASE_SERVICE_ACCOUNT_JSON')
        
        if env_cred_json:
            import json
            service_data = json.loads(env_cred_json)
            cred = credentials.Certificate(service_data)
            firebase_admin.initialize_app(cred)
            db = firestore.client()
            print("✅ Firebase Admin SDK initialized from environment variable!")
        elif os.path.exists(cred_path):
            import json
            with open(cred_path, 'r') as f:
                service_data = json.load(f)
            
            if service_data.get('type') != 'service_account':
                print("\n❌ ERROR: The JSON file is not a valid service account key!")
                db = None
            else:
                cred = credentials.Certificate(cred_path)
                firebase_admin.initialize_app(cred)
                db = firestore.client()
                print("✅ Firebase Admin SDK initialized from serviceAccountKey.json!")
        else:
            print("\n⚠️ WARNING: Firebase Service Account Key Not Found! Running in DEMO MODE")
            db = None
                
except Exception as e:
    print(f"\n❌ Error initializing Firebase: {str(e)}")
    print("Running in DEMO MODE without Firebase connection\n")
    db = None

# Admin credentials (in production, store these securely in environment variables)
ADMIN_CREDENTIALS = {
    'admin@mediconnect.com': generate_password_hash('admin123')  # Change this password in production!
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
            "total_appointments": 0,
            "total_ambulances": 0,
            "total_diagnostic_centres": 0
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
        
        # Get ambulance stats
        ambulances_ref = db.collection('ambulances')
        total_ambulances = len(list(ambulances_ref.stream()))
        
        # Get diagnostic centres stats
        diagnostic_centres_ref = db.collection('diagnostic_centres')
        total_diagnostic_centres = len(list(diagnostic_centres_ref.stream()))
        
        return {
            "total_doctors": total_doctors,
            "total_patients": total_patients,
            "pending_verifications": pending_verifications,
            "approved_doctors": approved_doctors,
            "rejected_doctors": rejected_doctors,
            "total_appointments": total_appointments,
            "total_diagnostic_centres": total_diagnostic_centres
        }
    except Exception as e:
        print(f"Error getting stats: {e}")
        return {
            "total_doctors": 0,
            "total_patients": 0,
            "pending_verifications": 0,
            "approved_doctors": 0,
            "rejected_doctors": 0,
            "total_appointments": 0,
            "total_diagnostic_centres": 0
        }

# =================== Authentication Routes ===================

@app.route('/')
@login_required
def index():
    role = session.get('user_role')
    if role == 'doctor':
        return redirect(url_for('doctor_dashboard'))
    elif role in ['diagnostic_centre', 'diagnostic']:
        return redirect(url_for('diagnostic_dashboard'))
    return redirect(url_for('dashboard'))

# =================== Registration Web Routes ===================

@app.route('/register/doctor', methods=['GET', 'POST'])
def register_doctor():
    if request.method == 'POST':
        name = request.form.get('name')
        email = request.form.get('email')
        password = request.form.get('password')
        phone = request.form.get('phone')
        specialization = request.form.get('specialization')
        bmdcNumber = request.form.get('bmdcNumber')
        workplaceHospital = request.form.get('workplaceHospital')
        workplaceDepartment = request.form.get('workplaceDepartment')
        qualifications = request.form.get('qualifications')
        experience = int(request.form.get('experience', 5))
        consultationFee = float(request.form.get('consultationFee', 800))

        if db is not None:
            try:
                existing = list(db.collection('users').where('email', '==', email).stream())
                if existing:
                    flash('Email already registered! Please sign in.', 'danger')
                    return redirect(url_for('register_doctor'))

                user_id = email.replace('@', '_at_').replace('.', '_dot_')
                try:
                    user_record = auth.create_user(email=email, password=password, display_name=name)
                    user_id = user_record.uid
                except Exception as auth_err:
                    print(f"Firebase Auth Notice: {auth_err}")

                db.collection('users').document(user_id).set({
                    'userId': user_id,
                    'name': name,
                    'email': email,
                    'phone': phone,
                    'role': 'doctor',
                    'verificationStatus': 'pending',
                    'createdAt': datetime.now()
                })

                db.collection('doctors').document(user_id).set({
                    'id': user_id,
                    'userId': user_id,
                    'name': name,
                    'email': email,
                    'phone': phone,
                    'specialization': specialization,
                    'bmdcNumber': bmdcNumber,
                    'workplaceHospital': workplaceHospital,
                    'workplaceDepartment': workplaceDepartment,
                    'qualifications': qualifications,
                    'experience': experience,
                    'consultationFee': consultationFee,
                    'verificationStatus': 'pending',
                    'createdAt': datetime.now()
                })

                session['admin_email'] = email
                session['user_id'] = user_id
                session['user_email'] = email
                session['user_role'] = 'doctor'
                session['user_name'] = name
                session['verification_status'] = 'pending'

                flash('Doctor registration submitted! Verification is pending admin review.', 'info')
                return redirect(url_for('verification_pending'))
            except Exception as e:
                flash(f'Registration error: {e}', 'danger')
        else:
            session['admin_email'] = email
            session['user_id'] = 'demo_doctor'
            session['user_email'] = email
            session['user_role'] = 'doctor'
            session['user_name'] = name
            session['verification_status'] = 'pending'
            flash('Demo Mode: Doctor registration submitted! Status is pending.', 'info')
            return redirect(url_for('verification_pending'))

    return render_template('register_doctor.html')


@app.route('/register/diagnostic', methods=['GET', 'POST'])
def register_diagnostic():
    if request.method == 'POST':
        name = request.form.get('name')
        email = request.form.get('email')
        password = request.form.get('password')
        phone = request.form.get('phone')
        city = request.form.get('city')
        address = request.form.get('address')
        dghsCode = request.form.get('dghsCode')
        pathologistName = request.form.get('pathologistName')
        pathologistBmdcNumber = request.form.get('pathologistBmdcNumber')
        tradeLicenseNumber = request.form.get('tradeLicenseNumber')
        operatingHours = request.form.get('operatingHours')
        homeCollectionFee = float(request.form.get('homeCollectionFee', 150))

        if db is not None:
            try:
                existing = list(db.collection('users').where('email', '==', email).stream())
                if existing:
                    flash('Email already registered! Please sign in.', 'danger')
                    return redirect(url_for('register_diagnostic'))

                user_id = email.replace('@', '_at_').replace('.', '_dot_')
                try:
                    user_record = auth.create_user(email=email, password=password, display_name=name)
                    user_id = user_record.uid
                except Exception as auth_err:
                    print(f"Firebase Auth Notice: {auth_err}")

                db.collection('users').document(user_id).set({
                    'userId': user_id,
                    'name': name,
                    'email': email,
                    'phone': phone,
                    'role': 'diagnostic_centre',
                    'verificationStatus': 'pending',
                    'dghsCode': dghsCode,
                    'pathologistName': pathologistName,
                    'pathologistBmdcNumber': pathologistBmdcNumber,
                    'createdAt': datetime.now()
                })

                db.collection('diagnostic_centres').document(user_id).set({
                    'id': user_id,
                    'name': name,
                    'email': email,
                    'phone': phone,
                    'city': city,
                    'address': address,
                    'dghsCode': dghsCode,
                    'pathologistName': pathologistName,
                    'pathologistBmdcNumber': pathologistBmdcNumber,
                    'tradeLicenseNumber': tradeLicenseNumber,
                    'operatingHours': operatingHours,
                    'homeCollectionFee': homeCollectionFee,
                    'isEmergencyAvailable': True,
                    'verificationStatus': 'pending',
                    'verificationNote': 'DGHS Code & Pathologist BMDC submitted for admin review',
                    'createdAt': datetime.now()
                })

                session['admin_email'] = email
                session['user_id'] = user_id
                session['user_email'] = email
                session['user_role'] = 'diagnostic_centre'
                session['user_name'] = name
                session['verification_status'] = 'pending'

                flash('Diagnostic Centre registration submitted with DGHS Code & Pathologist BMDC! Verification pending admin review.', 'info')
                return redirect(url_for('verification_pending'))
            except Exception as e:
                flash(f'Registration error: {e}', 'danger')
        else:
            session['admin_email'] = email
            session['user_id'] = 'demo_diag'
            session['user_email'] = email
            session['user_role'] = 'diagnostic_centre'
            session['user_name'] = name
            session['verification_status'] = 'pending'
            flash('Demo Mode: Diagnostic Centre registration submitted! Status is pending.', 'info')
            return redirect(url_for('verification_pending'))

    return render_template('register_diagnostic.html')


@app.route('/register/patient', methods=['GET', 'POST'])
def register_patient():
    if request.method == 'POST':
        name = request.form.get('name')
        email = request.form.get('email')
        password = request.form.get('password')
        confirm_password = request.form.get('confirm_password')
        phone = request.form.get('phone')
        dob = request.form.get('dob')
        gender = request.form.get('gender')
        blood_group = request.form.get('blood_group')
        emergency_contact = request.form.get('emergency_contact')

        if password != confirm_password:
            flash('Passwords do not match!', 'danger')
            return redirect(url_for('register_patient'))

        if db is not None:
            try:
                existing = list(db.collection('users').where('email', '==', email).stream())
                if existing:
                    flash('Email already registered! Please sign in.', 'danger')
                    return redirect(url_for('register_patient'))

                user_id = email.replace('@', '_at_').replace('.', '_dot_')
                try:
                    user_record = auth.create_user(email=email, password=password, display_name=name)
                    user_id = user_record.uid
                except Exception as auth_err:
                    print(f"Firebase Auth Notice: {auth_err}")

                db.collection('users').document(user_id).set({
                    'userId': user_id,
                    'name': name,
                    'email': email,
                    'phone': phone,
                    'role': 'patient',
                    'dob': dob,
                    'gender': gender,
                    'blood_group': blood_group,
                    'emergency_contact': emergency_contact,
                    'isApproved': True,
                    'createdAt': datetime.now()
                })

                session['admin_email'] = email
                session['user_id'] = user_id
                session['user_email'] = email
                session['user_role'] = 'patient'
                session['user_name'] = name

                flash(f'Welcome to MediConnect, {name}!', 'success')
                return redirect(url_for('patient_dashboard'))
            except Exception as e:
                flash(f'Registration error: {e}', 'danger')
        else:
            session['admin_email'] = email
            session['user_id'] = 'demo_patient_id'
            session['user_email'] = email
            session['user_role'] = 'patient'
            session['user_name'] = name
            flash('Logged in to Patient Web Portal (Demo Mode)', 'info')
            return redirect(url_for('patient_dashboard'))

    return render_template('register_patient.html')

@app.route('/admin')
@app.route('/admin/login', methods=['GET', 'POST'])
def admin_login():
    if request.method == 'POST':
        email = request.form.get('email')
        password = request.form.get('password')
        
        if email in ADMIN_CREDENTIALS and check_password_hash(ADMIN_CREDENTIALS[email], password):
            session['admin_email'] = email
            session['user_id'] = 'admin_super'
            session['user_email'] = email
            session['user_role'] = 'admin'
            session['user_name'] = 'Super Admin'
            session['verification_status'] = 'approved'
            flash('Logged in as Super Admin!', 'success')
            return redirect(url_for('dashboard'))
        else:
            flash('Invalid Super Admin credentials.', 'danger')
            
    return render_template('admin_login.html')


@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        email = request.form.get('email')
        password = request.form.get('password')
        login_role = request.form.get('login_role', 'doctor')
        
        # Prevent admin login via public portal gateway
        if login_role == 'admin':
            flash('Admin login is restricted to the secure admin gateway link.', 'warning')
            return redirect(url_for('login'))
            
        # Doctor & Diagnostic Centre Check in Firestore
        if db is not None:
            try:
                # Check users collection
                user_docs = list(db.collection('users').where('email', '==', email).stream())
                if user_docs:
                    user = user_docs[0].to_dict()
                    uid = user_docs[0].id
                    role = user.get('role', 'doctor')
                    name = user.get('name', 'User')
                    v_status = user.get('verificationStatus', 'approved')
                    
                    session['admin_email'] = email
                    session['user_id'] = uid
                    session['user_email'] = email
                    session['user_role'] = role
                    session['user_name'] = name
                    session['verification_status'] = v_status
                    
                    if role == 'doctor':
                        doc_check = db.collection('doctors').document(uid).get()
                        if doc_check.exists:
                            v_status = doc_check.to_dict().get('verificationStatus', 'pending')
                            session['verification_status'] = v_status
                        if v_status != 'approved':
                            flash('Your Doctor verification is pending admin review. Dashboard access restricted.', 'warning')
                            return redirect(url_for('verification_pending'))
                        flash(f'Welcome back, Dr. {name}!', 'success')
                        return redirect(url_for('doctor_dashboard'))
                    elif role in ['diagnostic_centre', 'diagnostic']:
                        diag_check = db.collection('diagnostic_centres').document(uid).get()
                        if diag_check.exists:
                            v_status = diag_check.to_dict().get('verificationStatus', 'pending')
                            session['verification_status'] = v_status
                        if v_status != 'approved':
                            flash('Your Diagnostic Centre verification is pending admin review.', 'warning')
                            return redirect(url_for('verification_pending'))
                        flash(f'Welcome back, {name}!', 'success')
                        return redirect(url_for('diagnostic_dashboard'))
                    elif role == 'patient':
                        flash(f'Welcome back, {name}!', 'success')
                        return redirect(url_for('patient_dashboard'))
                
                # Also check doctors collection directly
                doctor_docs = list(db.collection('doctors').where('email', '==', email).stream())
                if doctor_docs:
                    doc = doctor_docs[0].to_dict()
                    uid = doctor_docs[0].id
                    name = doc.get('name', 'Doctor')
                    v_status = doc.get('verificationStatus', 'pending')
                    session['admin_email'] = email
                    session['user_id'] = uid
                    session['user_email'] = email
                    session['user_role'] = 'doctor'
                    session['user_name'] = name
                    session['verification_status'] = v_status
                    if v_status != 'approved':
                        flash('Your Doctor verification is pending admin review.', 'warning')
                        return redirect(url_for('verification_pending'))
                    flash(f'Welcome back, Dr. {name}!', 'success')
                    return redirect(url_for('doctor_dashboard'))

                # Also check diagnostic_centres collection directly
                diag_docs = list(db.collection('diagnostic_centres').where('email', '==', email).stream())
                if diag_docs:
                    diag = diag_docs[0].to_dict()
                    uid = diag_docs[0].id
                    name = diag.get('name', 'Diagnostic Centre')
                    v_status = diag.get('verificationStatus', 'pending')
                    session['admin_email'] = email
                    session['user_id'] = uid
                    session['user_email'] = email
                    session['user_role'] = 'diagnostic_centre'
                    session['user_name'] = name
                    session['verification_status'] = v_status
                    if v_status != 'approved':
                        flash('Your Diagnostic Centre verification is pending admin review.', 'warning')
                        return redirect(url_for('verification_pending'))
                    flash(f'Welcome back, {name}!', 'success')
                    return redirect(url_for('diagnostic_dashboard'))
            except Exception as e:
                print(f"Error checking Firestore login: {e}")

        # Fallback / Quick portal login keywords for convenience
        if 'patient' in email.lower() or login_role == 'patient':
            session['admin_email'] = email
            session['user_id'] = 'demo_patient_id'
            session['user_email'] = email
            session['user_role'] = 'patient'
            session['user_name'] = email.split('@')[0].capitalize()
            flash('Logged in to Patient Web Portal (Demo Mode)', 'info')
            return redirect(url_for('patient_dashboard'))

        if 'doctor' in email.lower():
            session['admin_email'] = email
            session['user_id'] = 'demo_doctor_id'
            session['user_email'] = email
            session['user_role'] = 'doctor'
            session['user_name'] = email.split('@')[0].capitalize()
            flash('Logged in to Doctor Web Portal (Demo Mode)', 'info')
            return redirect(url_for('doctor_dashboard'))

        if 'diag' in email.lower():
            session['admin_email'] = email
            session['user_id'] = 'demo_diag_id'
            session['user_email'] = email
            session['user_role'] = 'diagnostic_centre'
            session['user_name'] = email.split('@')[0].capitalize()
            flash('Logged in to Diagnostic Web Portal (Demo Mode)', 'info')
            return redirect(url_for('diagnostic_dashboard'))

        flash('Invalid email or password', 'danger')

    return render_template('login.html')

@app.route('/logout')
def logout():
    session.clear()
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
            
            # Calculate age from dateOfBirth
            if 'dateOfBirth' in patient_data and patient_data['dateOfBirth']:
                try:
                    dob = patient_data['dateOfBirth']
                    if isinstance(dob, str):
                        dob = datetime.fromisoformat(dob.replace('Z', '+00:00'))
                    elif hasattr(dob, 'timestamp'):
                        # Firestore timestamp
                        dob = datetime.fromtimestamp(dob.timestamp())
                    
                    today = datetime.now()
                    age = today.year - dob.year
                    if (today.month, today.day) < (dob.month, dob.day):
                        age -= 1
                    patient_data['age'] = age
                except:
                    patient_data['age'] = None
            else:
                patient_data['age'] = None
            
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

# =================== Diagnostic Centre Management Routes ===================

@app.route('/diagnostic-centres')
@login_required
def diagnostic_centres():
    """Diagnostic centres management page"""
    if db is None:
        flash('Firebase not connected. Showing demo data.', 'warning')
        return render_template('diagnostic_centres.html', centres=[], stats={'total': 0, 'active': 0, 'inactive': 0})
    
    try:
        centres_ref = db.collection('diagnostic_centres')
        
        # Get filter parameters
        search_query = request.args.get('search', '').strip()
        status_filter = request.args.get('status', '')
        
        centres_list = []
        
        for doc in centres_ref.stream():
            centre_data = doc.to_dict()
            centre_data['id'] = doc.id
            
            # Apply search filter
            if search_query:
                search_lower = search_query.lower()
                if not (search_lower in centre_data.get('name', '').lower() or
                        search_lower in centre_data.get('address', '').lower() or
                        search_lower in centre_data.get('contactNumber', '').lower()):
                    continue
            
            # Apply status filter
            if status_filter and centre_data.get('status') != status_filter:
                continue
            
            centres_list.append(centre_data)
        
        # Calculate statistics
        all_centres = [c.to_dict() for c in db.collection('diagnostic_centres').stream()]
        stats = {
            'total': len(all_centres),
            'approved': sum(1 for c in all_centres if c.get('verificationStatus') == 'approved' or c.get('status') == 'active'),
            'pending': sum(1 for c in all_centres if c.get('verificationStatus') == 'pending' or (c.get('verificationStatus') != 'approved' and c.get('verificationStatus') != 'rejected')),
            'rejected': sum(1 for c in all_centres if c.get('verificationStatus') == 'rejected'),
        }
        
        return render_template('diagnostic_centres.html', centres=centres_list, stats=stats)
    except Exception as e:
        flash(f'Error loading diagnostic centres: {str(e)}', 'danger')
        empty_stats = {'total': 0, 'approved': 0, 'pending': 0, 'rejected': 0}
        return render_template('diagnostic_centres.html', centres=[], stats=empty_stats)


@app.route('/diagnostic-centres/add', methods=['POST'])
@login_required
def add_diagnostic_centre():
    """Add a new diagnostic centre with verification info"""
    if db is None:
        flash('Firebase not connected. Cannot add diagnostic centre.', 'warning')
        return redirect(url_for('diagnostic_centres'))
    
    try:
        name = request.form.get('name', '').strip()
        address = request.form.get('address', '').strip()
        city = request.form.get('city', '').strip()
        contact_number = request.form.get('contactNumber', '').strip()
        dghs_code = request.form.get('dghsCode', '').strip()
        pathologist_name = request.form.get('pathologistName', '').strip()
        pathologist_bmdc = request.form.get('pathologistBmdcNumber', '').strip()
        
        if not name or not contact_number:
            flash('Please fill in required fields.', 'danger')
            return redirect(url_for('diagnostic_centres'))
        
        centre_data = {
            'name': name,
            'address': address,
            'city': city,
            'contactNumber': contact_number,
            'dghsCode': dghs_code,
            'pathologistName': pathologist_name,
            'pathologistBmdcNumber': pathologist_bmdc,
            'verificationStatus': 'approved',
            'status': 'active',
            'createdAt': datetime.now().isoformat(),
            'updatedAt': datetime.now().isoformat()
        }
        
        db.collection('diagnostic_centres').add(centre_data)
        flash(f'Diagnostic centre "{name}" registered and verified successfully!', 'success')
        
    except Exception as e:
        flash(f'Error adding diagnostic centre: {str(e)}', 'danger')
    
    return redirect(url_for('diagnostic_centres'))


@app.route('/diagnostic-centres/<centre_id>/verify', methods=['POST'])
@login_required
def verify_diagnostic_centre(centre_id):
    """Verify and approve a diagnostic centre via DGHS & BMDC code"""
    if db is None:
        flash('Firebase not connected.', 'warning')
        return redirect(url_for('diagnostic_centres'))
    
    try:
        centre_ref = db.collection('diagnostic_centres').document(centre_id)
        doc = centre_ref.get()
        if not doc.exists:
            flash('Diagnostic centre not found.', 'danger')
            return redirect(url_for('diagnostic_centres'))
        
        centre_name = doc.to_dict().get('name', 'Diagnostic Centre')

        centre_ref.update({
            'verificationStatus': 'approved',
            'status': 'active',
            'updatedAt': datetime.now().isoformat()
        })

        flash(f'Diagnostic Centre "{centre_name}" verified & approved successfully via DGHS & Pathologist BMDC!', 'success')
    except Exception as e:
        flash(f'Error verifying diagnostic centre: {str(e)}', 'danger')

    return redirect(url_for('diagnostic_centres'))


@app.route('/diagnostic-centres/<centre_id>/reject', methods=['POST'])
@login_required
def reject_diagnostic_centre(centre_id):
    """Reject a diagnostic centre verification application"""
    if db is None:
        flash('Firebase not connected.', 'warning')
        return redirect(url_for('diagnostic_centres'))
    
    try:
        centre_ref = db.collection('diagnostic_centres').document(centre_id)
        doc = centre_ref.get()
        if not doc.exists:
            flash('Diagnostic centre not found.', 'danger')
            return redirect(url_for('diagnostic_centres'))
        
        centre_name = doc.to_dict().get('name', 'Diagnostic Centre')
        rejection_reason = request.form.get('rejection_reason', 'DGHS code or Pathologist BMDC verification failed').strip()

        centre_ref.update({
            'verificationStatus': 'rejected',
            'status': 'inactive',
            'rejectionReason': rejection_reason,
            'updatedAt': datetime.now().isoformat()
        })

        flash(f'Diagnostic Centre "{centre_name}" verification rejected.', 'warning')
    except Exception as e:
        flash(f'Error rejecting diagnostic centre: {str(e)}', 'danger')

    return redirect(url_for('diagnostic_centres'))


@app.route('/diagnostic-centres/update', methods=['POST'])
@login_required
def update_diagnostic_centre():
    """Update diagnostic centre verification info"""
    if db is None:
        flash('Firebase not connected. Cannot update diagnostic centre.', 'warning')
        return redirect(url_for('diagnostic_centres'))
    
    try:
        centre_id = request.form.get('centre_id')
        name = request.form.get('name', '').strip()
        address = request.form.get('address', '').strip()
        city = request.form.get('city', '').strip()
        contact_number = request.form.get('contactNumber', '').strip()
        dghs_code = request.form.get('dghsCode', '').strip()
        pathologist_name = request.form.get('pathologistName', '').strip()
        pathologist_bmdc = request.form.get('pathologistBmdcNumber', '').strip()
        status = request.form.get('status', 'active')
        
        if not centre_id:
            flash('Diagnostic centre ID is required.', 'danger')
            return redirect(url_for('diagnostic_centres'))
        
        centre_ref = db.collection('diagnostic_centres').document(centre_id)
        
        if not centre_ref.get().exists:
            flash('Diagnostic centre not found.', 'danger')
            return redirect(url_for('diagnostic_centres'))
        
        centre_ref.update({
            'name': name,
            'address': address,
            'city': city,
            'contactNumber': contact_number,
            'dghsCode': dghs_code,
            'pathologistName': pathologist_name,
            'pathologistBmdcNumber': pathologist_bmdc,
            'status': status,
            'updatedAt': datetime.now().isoformat()
        })
        
        flash(f'Diagnostic centre "{name}" updated successfully!', 'success')
        
    except Exception as e:
        flash(f'Error updating diagnostic centre: {str(e)}', 'danger')
    
    return redirect(url_for('diagnostic_centres'))


@app.route('/diagnostic-centres/<centre_id>/delete', methods=['POST'])
@login_required
def delete_diagnostic_centre(centre_id):
    """Delete a diagnostic centre"""
    if db is None:
        flash('Firebase not connected. Cannot delete diagnostic centre.', 'warning')
        return redirect(url_for('diagnostic_centres'))
    
    try:
        centre_ref = db.collection('diagnostic_centres').document(centre_id)
        doc = centre_ref.get()
        
        if not doc.exists:
            flash('Diagnostic centre not found.', 'danger')
            return redirect(url_for('diagnostic_centres'))
        
        centre_name = doc.to_dict().get('name', 'Unknown')
        centre_ref.delete()
        
        flash(f'Diagnostic centre "{centre_name}" deleted successfully!', 'success')
        
    except Exception as e:
        flash(f'Error deleting diagnostic centre: {str(e)}', 'danger')
    
    return redirect(url_for('diagnostic_centres'))


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

# =================== Disease Heatmap & Outbreak Analytics ===================

DEFAULT_HEATMAP_CLUSTERS = [
    {'region': 'Dhaka Central', 'lat': 23.8103, 'lng': 90.4125, 'disease': 'Dengue Fever', 'cases': 142, 'trend': '+18%'},
    {'region': 'Chittagong Port Zone', 'lat': 22.3569, 'lng': 91.7832, 'disease': 'Seasonal Flu', 'cases': 88, 'trend': '+8%'},
    {'region': 'Sylhet Metro', 'lat': 24.8949, 'lng': 91.8687, 'disease': 'Typhoid', 'cases': 64, 'trend': '-3%'},
    {'region': 'Rajshahi City', 'lat': 24.3636, 'lng': 88.6241, 'disease': 'Viral Fever', 'cases': 45, 'trend': '+5%'},
    {'region': 'Khulna Coastal', 'lat': 22.8456, 'lng': 89.5403, 'disease': 'Cholera', 'cases': 38, 'trend': '-12%'},
    {'region': 'Barisal Division', 'lat': 22.7010, 'lng': 90.3535, 'disease': 'COVID-19', 'cases': 29, 'trend': '-5%'},
    {'region': 'Rangpur North', 'lat': 25.7439, 'lng': 89.2752, 'disease': 'Dengue Fever', 'cases': 52, 'trend': '+12%'},
    {'region': 'Mymensingh Center', 'lat': 24.7471, 'lng': 90.4203, 'disease': 'Seasonal Flu', 'cases': 41, 'trend': '+2%'}
]

@app.route('/disease-heatmap')
@login_required
def disease_heatmap():
    """Render Disease Heatmap & Outbreak Analytics page"""
    clusters = list(DEFAULT_HEATMAP_CLUSTERS)
    
    # Try fetching real data from Firestore if connected
    if db is not None:
        try:
            # Query recent appointments or symptom checks if present
            symptom_docs = list(db.collection('symptom_checks').limit(100).stream())
            if symptom_docs:
                diag_counts = {}
                for doc in symptom_docs:
                    data = doc.to_dict()
                    diag = data.get('possibleCondition') or data.get('disease') or 'Viral Fever'
                    diag_counts[diag] = diag_counts.get(diag, 0) + 1
        except Exception as e:
            print(f"Firestore query for heatmap error: {e}")

    total_cases = sum(c['cases'] for c in clusters)
    high_risk_zones = sum(1 for c in clusters if c['cases'] >= 50)
    top_cluster = max(clusters, key=lambda c: c['cases']) if clusters else {'region': 'Dhaka Central'}
    
    disease_counts = {}
    for c in clusters:
        disease_counts[c['disease']] = disease_counts.get(c['disease'], 0) + c['cases']
    top_disease = max(disease_counts.items(), key=lambda x: x[1])[0] if disease_counts else 'Dengue Fever'

    heatmap_summary = {
        'total_cases': total_cases,
        'high_risk_zones': high_risk_zones,
        'primary_outbreak': top_cluster['region'],
        'top_disease': top_disease
    }

    disease_breakdown = [
        {'name': name, 'cases': cases, 'cluster_count': sum(1 for c in clusters if c['disease'] == name), 'trend': 'Active'}
        for name, cases in disease_counts.items()
    ]

    return render_template('disease_heatmap.html',
                           heatmap_summary=heatmap_summary,
                           regional_clusters=clusters,
                           disease_breakdown=disease_breakdown)


@app.route('/api/disease-heatmap-data')
@login_required
def api_disease_heatmap_data():
    """JSON API endpoint for filtered heatmap map markers"""
    from flask import jsonify
    disease_filter = request.args.get('disease', 'all')
    
    clusters = list(DEFAULT_HEATMAP_CLUSTERS)
    if disease_filter != 'all':
        clusters = [c for c in clusters if c['disease'].lower() == disease_filter.lower()]

    total_cases = sum(c['cases'] for c in clusters)
    high_risk_zones = sum(1 for c in clusters if c['cases'] >= 50)
    top_cluster = max(clusters, key=lambda c: c['cases']) if clusters else {'region': 'N/A'}
    
    disease_counts = {}
    for c in clusters:
        disease_counts[c['disease']] = disease_counts.get(c['disease'], 0) + c['cases']
    top_disease = max(disease_counts.items(), key=lambda x: x[1])[0] if disease_counts else 'N/A'

    summary = {
        'total_cases': total_cases,
        'high_risk_zones': high_risk_zones,
        'primary_outbreak': top_cluster['region'],
        'top_disease': top_disease
    }

    return jsonify({
        'clusters': clusters,
        'summary': summary
    })

@app.route('/verification-pending')
def verification_pending():
    if not session.get('user_email') and not session.get('admin_email'):
        return redirect(url_for('login'))
        
    user_id = session.get('user_id')
    role = session.get('user_role', 'doctor')
    user_data = {}
    status = session.get('verification_status', 'pending')
    
    if db is not None and user_id:
        try:
            if role == 'doctor':
                doc = db.collection('doctors').document(user_id).get()
                if doc.exists:
                    user_data = doc.to_dict()
                    status = user_data.get('verificationStatus', 'pending')
            elif role in ['diagnostic_centre', 'diagnostic']:
                doc = db.collection('diagnostic_centres').document(user_id).get()
                if doc.exists:
                    user_data = doc.to_dict()
                    status = user_data.get('verificationStatus', 'pending')
            else:
                doc = db.collection('users').document(user_id).get()
                if doc.exists:
                    user_data = doc.to_dict()
                    status = user_data.get('verificationStatus', 'pending')
                    
            session['verification_status'] = status
            if status == 'approved':
                flash('Congratulations! Your account has been approved by Admin.', 'success')
                if role == 'doctor':
                    return redirect(url_for('doctor_dashboard'))
                elif role in ['diagnostic_centre', 'diagnostic']:
                    return redirect(url_for('diagnostic_dashboard'))
        except Exception as e:
            print(f"Error checking verification status: {e}")
            
    return render_template('verification_pending.html',
                           role=role,
                           status=status,
                           user_data=user_data)

def is_appointment_for_doctor(appt_data, doctor_id, user_email, user_name):
    """Check if an appointment belongs to the specified doctor using ID, email, or name matching"""
    if not appt_data or not isinstance(appt_data, dict):
        return False
        
    doc_id = str(appt_data.get('doctorId') or '').strip()
    doc_email = str(appt_data.get('doctorEmail') or '').lower().strip()
    doc_name = str(appt_data.get('doctorName') or '').lower().strip()
    
    target_id = str(doctor_id or '').strip()
    target_email = str(user_email or '').lower().strip()
    target_name = str(user_name or '').lower().strip()
    
    # 1. Match by Exact Doctor ID
    if target_id and doc_id and doc_id == target_id:
        return True
        
    # 2. Match by Doctor Email
    if target_email and (doc_email == target_email or doc_id == target_email):
        return True
        
    # 3. Match by Name (stripping Dr. prefix)
    clean_target = target_name.replace('dr.', '').replace('dr', '').strip()
    clean_doc = doc_name.replace('dr.', '').replace('dr', '').strip()
    
    if clean_target and clean_doc and len(clean_target) >= 3:
        if clean_target == clean_doc or clean_target in clean_doc or clean_doc in clean_target:
            return True
            
    return False

# =================== Doctor & Diagnostic Auth Decorators ===================

def doctor_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        role = session.get('user_role')
        if role == 'admin':
            flash('Access restricted to Doctors. You are logged in as Super Admin.', 'warning')
            return redirect(url_for('dashboard'))
            
        if 'user_email' not in session or role != 'doctor':
            flash('Please login with your Doctor account to access Doctor Portal', 'warning')
            return redirect(url_for('login'))
            
        if session.get('verification_status') != 'approved':
            flash('Your Doctor account is pending admin verification.', 'warning')
            return redirect(url_for('verification_pending'))
            
        return f(*args, **kwargs)
    return decorated_function

def diagnostic_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        role = session.get('user_role')
        if role == 'admin':
            flash('Access restricted to Diagnostic Centres. You are logged in as Super Admin.', 'warning')
            return redirect(url_for('dashboard'))
            
        if 'user_email' not in session or role not in ['diagnostic_centre', 'diagnostic']:
            flash('Please login with your Diagnostic Centre account', 'warning')
            return redirect(url_for('login'))
            
        if session.get('verification_status') != 'approved':
            flash('Your Diagnostic Centre account is pending admin verification.', 'warning')
            return redirect(url_for('verification_pending'))
            
        return f(*args, **kwargs)
    return decorated_function

# =================== Doctor Web Portal Routes ===================

@app.route('/doctor/dashboard')
@doctor_required
def doctor_dashboard():
    doctor_id = session.get('user_id')
    user_email = session.get('user_email')
    user_name = session.get('user_name', '')
    today_str = datetime.now().strftime('%Y-%m-%d')
    
    appointments = []
    today_count = 0
    pending_count = 0
    completed_count = 0
    total_earnings = 0.0

    if db is not None:
        try:
            docs = list(db.collection('appointments').stream())
            for d in docs:
                data = d.to_dict()
                data['id'] = d.id
                
                if is_appointment_for_doctor(data, doctor_id, user_email, user_name):
                    appointments.append(data)
                    status = data.get('status', 'pending').lower()
                    
                    if data.get('date') == today_str or data.get('createdAt') == today_str:
                        today_count += 1
                        
                    if status == 'pending':
                        pending_count += 1
                    elif status == 'completed':
                        completed_count += 1
                        total_earnings += float(data.get('fee') or data.get('consultationFee') or 500)
        except Exception as e:
            print(f"Error fetching doctor appointments: {e}")
            
    return render_template('doctor/dashboard.html',
                           active_page='dashboard',
                           appointments=appointments,
                           today_count=today_count,
                           pending_count=pending_count,
                           completed_count=completed_count,
                           total_earnings=total_earnings)

@app.route('/doctor/appointments')
@doctor_required
def doctor_appointments():
    status_filter = request.args.get('status', '').strip().lower()
    doctor_id = session.get('user_id')
    user_email = session.get('user_email')
    user_name = session.get('user_name', '')
    today_str = datetime.now().strftime('%Y-%m-%d')
    
    appointments = []
    stats = {'total': 0, 'pending': 0, 'approved': 0, 'completed': 0, 'missed': 0, 'cancelled': 0}
    
    if db is not None:
        try:
            docs = list(db.collection('appointments').stream())
            for d in docs:
                data = d.to_dict()
                data['id'] = d.id
                
                if is_appointment_for_doctor(data, doctor_id, user_email, user_name):
                    appt_status = data.get('status', 'pending').lower()
                    appt_date = data.get('date', '')
                    
                    # Auto-expire past unfulfilled appointments to 'missed'
                    if appt_date and appt_date < today_str and appt_status in ['pending', 'approved', 'scheduled']:
                        db.collection('appointments').document(d.id).update({
                            'status': 'missed',
                            'updatedAt': datetime.now().strftime('%Y-%m-%d %H:%M')
                        })
                        appt_status = 'missed'
                        data['status'] = 'missed'
                        
                        # Trigger notification to patient
                        patient_id = data.get('patientId')
                        if patient_id:
                            db.collection('notifications').add({
                                'userId': patient_id,
                                'patientId': patient_id,
                                'patientName': data.get('patientName', 'Patient'),
                                'doctorId': doctor_id,
                                'doctorName': session.get('user_name', 'Doctor'),
                                'title': 'Missed Appointment Alert',
                                'body': f"You missed your scheduled consultation on {appt_date}. Please reschedule or cancel.",
                                'type': 'missed_appointment',
                                'appointmentId': d.id,
                                'createdAt': datetime.now(),
                                'read': False
                            })

                    # Update stats count
                    if appt_status in stats:
                        stats[appt_status] += 1
                    stats['total'] += 1
                    
                    # Filter matching
                    if status_filter:
                        if appt_status == status_filter:
                            appointments.append(data)
                    else:
                        appointments.append(data)
        except Exception as e:
            print(f"Error fetching appointments: {e}")
            
    return render_template('doctor/appointments.html',
                           active_page='appointments',
                           appointments=appointments,
                           current_status=status_filter,
                           stats=stats)

@app.route('/doctor/appointment/<appointment_id>/<action>')
@doctor_required
def doctor_update_appointment(appointment_id, action):
    doctor_id = session.get('user_id')
    doctor_name = session.get('user_name', 'Doctor')
    
    if db is not None:
        try:
            doc_ref = db.collection('appointments').document(appointment_id)
            doc_snap = doc_ref.get()
            appt_data = doc_snap.to_dict() if doc_snap.exists else {}
            patient_id = appt_data.get('patientId')
            patient_name = appt_data.get('patientName', 'Patient')
            appt_date = appt_data.get('date', datetime.now().strftime('%Y-%m-%d'))
            
            if action == 'approve':
                doc_ref.update({'status': 'approved', 'updatedAt': datetime.now().strftime('%Y-%m-%d %H:%M')})
                flash('Appointment approved successfully!', 'success')
            elif action == 'cancel':
                doc_ref.update({'status': 'cancelled', 'updatedAt': datetime.now().strftime('%Y-%m-%d %H:%M')})
                flash('Appointment cancelled.', 'info')
            elif action == 'missed':
                doc_ref.update({'status': 'missed', 'updatedAt': datetime.now().strftime('%Y-%m-%d %H:%M')})
                
                # Send missed notification to patient
                if patient_id:
                    db.collection('notifications').add({
                        'userId': patient_id,
                        'patientId': patient_id,
                        'patientName': patient_name,
                        'doctorId': doctor_id,
                        'doctorName': doctor_name,
                        'title': 'Missed Appointment Alert',
                        'body': f"You missed your scheduled appointment with Dr. {doctor_name} on {appt_date}. Please reschedule or cancel.",
                        'type': 'missed_appointment',
                        'appointmentId': appointment_id,
                        'createdAt': datetime.now(),
                        'read': False
                    })
                flash(f'Marked appointment for {patient_name} as Missed. Notification sent to patient.', 'warning')
        except Exception as e:
            flash(f'Error updating appointment: {e}', 'danger')
    return redirect(url_for('doctor_appointments'))

@app.route('/doctor/prescription/write/<appointment_id>')
@doctor_required
def doctor_write_prescription(appointment_id):
    appointment = {'id': appointment_id, 'patientName': 'Patient', 'date': datetime.now().strftime('%Y-%m-%d')}
    if db is not None:
        try:
            doc = db.collection('appointments').document(appointment_id).get()
            if doc.exists:
                appointment = doc.to_dict()
                appointment['id'] = doc.id
        except Exception as e:
            print(f"Error fetching appointment: {e}")
            
    return render_template('doctor/write_prescription.html',
                           active_page='appointments',
                           appointment=appointment)

@app.route('/doctor/prescription/save/<appointment_id>', methods=['POST'])
@doctor_required
def doctor_save_prescription(appointment_id):
    doctor_id = session.get('user_id')
    doctor_name = session.get('user_name', 'Doctor')
    
    diagnosis = request.form.get('diagnosis')
    symptoms = request.form.get('symptoms')
    advice = request.form.get('advice')
    testsRecommended = request.form.get('testsRecommended')
    followUpDate = request.form.get('followUpDate')
    
    med_names = request.form.getlist('med_name[]')
    med_dosages = request.form.getlist('med_dosage[]')
    med_frequencies = request.form.getlist('med_frequency[]')
    med_durations = request.form.getlist('med_duration[]')
    med_instructions = request.form.getlist('med_instruction[]')
    
    medicines = []
    for i in range(len(med_names)):
        if med_names[i].strip():
            medicines.append({
                'name': med_names[i].strip(),
                'dosage': med_dosages[i].strip() if i < len(med_dosages) else '',
                'frequency': med_frequencies[i].strip() if i < len(med_frequencies) else '',
                'duration': med_durations[i].strip() if i < len(med_durations) else '',
                'instruction': med_instructions[i].strip() if i < len(med_instructions) else ''
            })
            
    patient_name = 'Patient'
    patient_id = ''
    if db is not None:
        try:
            appt_doc = db.collection('appointments').document(appointment_id).get()
            if appt_doc.exists:
                patient_name = appt_doc.to_dict().get('patientName', 'Patient')
                patient_id = appt_doc.to_dict().get('patientId', '')
                
            rx_ref = db.collection('prescriptions').document()
            rx_data = {
                'appointmentId': appointment_id,
                'doctorId': doctor_id,
                'doctorName': doctor_name,
                'patientId': patient_id,
                'patientName': patient_name,
                'diagnosis': diagnosis,
                'symptoms': symptoms,
                'advice': advice,
                'testsRecommended': testsRecommended,
                'followUpDate': followUpDate,
                'medicines': medicines,
                'date': datetime.now().strftime('%Y-%m-%d'),
                'createdAt': datetime.now()
            }
            rx_ref.set(rx_data)
            
            # Update appointment to completed
            db.collection('appointments').document(appointment_id).update({
                'status': 'completed',
                'prescriptionId': rx_ref.id,
                'updatedAt': datetime.now().strftime('%Y-%m-%d %H:%M')
            })
            flash('Prescription created and consultation completed!', 'success')
            return redirect(url_for('doctor_view_prescription', prescription_id=rx_ref.id))
        except Exception as e:
            flash(f'Error saving prescription: {e}', 'danger')
            
    return redirect(url_for('doctor_appointments'))

@app.route('/doctor/prescription/view/<prescription_id>')
@doctor_required
def doctor_view_prescription(prescription_id):
    rx = {'id': prescription_id, 'patientName': 'Patient', 'medicines': []}
    doctor_info = {'name': session.get('user_name', 'Doctor')}
    if db is not None:
        try:
            doc = db.collection('prescriptions').document(prescription_id).get()
            if doc.exists:
                rx = doc.to_dict()
                rx['id'] = doc.id
                
            doc_info = db.collection('doctors').document(rx.get('doctorId', session.get('user_id'))).get()
            if doc_info.exists:
                doctor_info = doc_info.to_dict()
        except Exception as e:
            print(f"Error fetching prescription: {e}")
            
    return render_template('doctor/view_prescription.html', rx=rx, doctor=doctor_info)

@app.route('/doctor/availability', methods=['GET', 'POST'])
@doctor_required
def doctor_availability():
    doctor_id = session.get('user_id')
    doctor_data = {}
    
    if db is not None and doctor_id:
        doc_ref = db.collection('doctors').document(doctor_id)
        if request.method == 'POST':
            availableDays = request.form.getlist('availableDays')
            startTime = request.form.get('startTime')
            endTime = request.form.get('endTime')
            slotDuration = int(request.form.get('slotDuration', 30))
            maxPatientsPerSlot = int(request.form.get('maxPatientsPerSlot', 1))
            availability_payload = {
                'availableDays': availableDays,
                'startTime': startTime,
                'endTime': endTime,
                'slotDuration': slotDuration,
                'maxPatientsPerSlot': maxPatientsPerSlot
            }
            doc_ref.set({
                'availability': availability_payload,
                'updatedAt': datetime.now()
            }, merge=True)
            flash('Schedule and availability updated!', 'success')
            return redirect(url_for('doctor_availability'))
            
        doc = doc_ref.get()
        if doc.exists:
            doctor_data = doc.to_dict()
            
    return render_template('doctor/availability.html',
                           active_page='availability',
                           doctor_data=doctor_data)

@app.route('/doctor/chambers')
@doctor_required
def doctor_chambers():
    doctor_id = session.get('user_id')
    chambers = []
    if db is not None and doctor_id:
        doc = db.collection('doctors').document(doctor_id).get()
        if doc.exists:
            chambers = doc.to_dict().get('chambers', [])
    return render_template('doctor/chambers.html', active_page='chambers', chambers=chambers)

@app.route('/doctor/chambers/add', methods=['POST'])
@doctor_required
def doctor_add_chamber():
    doctor_id = session.get('user_id')
    user_email = session.get('user_email')
    
    if db is not None and doctor_id:
        name = request.form.get('name')
        address = request.form.get('address')
        phone = request.form.get('phone')
        visitingHours = request.form.get('visitingHours')
        fee = float(request.form.get('fee', 500))
        
        chamber_id = f"c_{int(datetime.now().timestamp())}"
        
        new_chamber = {
            'id': chamber_id,
            'name': name,
            'chamberName': name,
            'hospitalName': name,
            'address': address,
            'fullAddress': address,
            'phone': phone,
            'contactPhone': phone,
            'visitingHours': visitingHours,
            'fee': fee,
            'consultationFee': fee,
            'doctorId': doctor_id,
            'doctorEmail': user_email,
            'isActive': True,
            'createdAt': datetime.now().isoformat()
        }
        
        # 1. Update doctors collection
        doc_ref = db.collection('doctors').document(doctor_id)
        doc = doc_ref.get()
        doc_data = doc.to_dict() if doc.exists else {}
        
        current_chambers = doc_data.get('chambers', [])
        current_hospitals = doc_data.get('hospitals', [])
        
        current_chambers.append(new_chamber)
        if name and name not in current_hospitals:
            current_hospitals.append(name)
            
        doc_ref.set({
            'chambers': current_chambers,
            'hospitals': current_hospitals,
            'hospital': name,
            'updatedAt': datetime.now()
        }, merge=True)
        
        # 2. Sync to users collection
        try:
            db.collection('users').document(doctor_id).set({
                'chambers': current_chambers,
                'hospitals': current_hospitals,
                'hospital': name,
                'updatedAt': datetime.now()
            }, merge=True)
        except Exception as sync_err:
            print(f"Chamber sync error to users: {sync_err}")
            
        # 3. Create document in top-level chambers collection
        try:
            db.collection('chambers').document(chamber_id).set(new_chamber)
        except Exception as top_err:
            print(f"Top level chambers collection add error: {top_err}")
            
        flash(f'Chamber "{name}" added and synced live for patients!', 'success')
    return redirect(url_for('doctor_chambers'))

@app.route('/doctor/chambers/delete/<int:index>')
@doctor_required
def doctor_delete_chamber(index):
    doctor_id = session.get('user_id')
    if db is not None and doctor_id:
        doc_ref = db.collection('doctors').document(doctor_id)
        doc = doc_ref.get()
        if doc.exists:
            doc_data = doc.to_dict()
            chambers = doc_data.get('chambers', [])
            hospitals = doc_data.get('hospitals', [])
            if 0 <= index < len(chambers):
                removed = chambers.pop(index)
                removed_name = removed.get('name')
                if removed_name in hospitals:
                    hospitals.remove(removed_name)
                    
                doc_ref.set({'chambers': chambers, 'hospitals': hospitals}, merge=True)
                try:
                    db.collection('users').document(doctor_id).set({'chambers': chambers, 'hospitals': hospitals}, merge=True)
                except Exception:
                    pass
                if removed.get('id'):
                    try:
                        db.collection('chambers').document(removed.get('id')).delete()
                    except Exception:
                        pass
                flash('Chamber removed.', 'info')
    return redirect(url_for('doctor_chambers'))

@app.route('/doctor/patients')
@doctor_required
def doctor_patients():
    doctor_id = session.get('user_id')
    user_email = session.get('user_email')
    user_name = session.get('user_name', '')
    search_query = request.args.get('search', '').strip().lower()
    
    doctor_patient_ids = set()
    doctor_patient_emails = set()
    
    if db is not None:
        try:
            appt_docs = list(db.collection('appointments').stream())
            for d in appt_docs:
                data = d.to_dict()
                if is_appointment_for_doctor(data, doctor_id, user_email, user_name):
                    pid = data.get('patientId')
                    pemail = data.get('patientEmail')
                    if pid:
                        doctor_patient_ids.add(pid)
                    if pemail:
                        doctor_patient_emails.add(pemail.lower())
        except Exception as e:
            print(f"Error fetching doctor patient IDs: {e}")
            
    patients = []
    if db is not None and (doctor_patient_ids or doctor_patient_emails):
        try:
            all_patients = list(db.collection('users').where('role', '==', 'patient').stream())
            for pdoc in all_patients:
                pdata = pdoc.to_dict()
                pid = pdoc.id
                pemail = (pdata.get('email') or '').lower()
                
                if pid in doctor_patient_ids or (pemail and pemail in doctor_patient_emails):
                    pdata['id'] = pid
                    if search_query:
                        if (search_query in pdata.get('name', '').lower() or
                            search_query in pdata.get('phone', '').lower() or
                            search_query in pemail):
                            patients.append(pdata)
                    else:
                        patients.append(pdata)
        except Exception as e:
            print(f"Error fetching patient records: {e}")
            
    return render_template('doctor/patients.html', active_page='patients', patients=patients, search_query=search_query)

@app.route('/doctor/request-access/<patient_id>')
@doctor_required
def doctor_request_access(patient_id):
    doctor_id = session.get('user_id')
    doctor_name = session.get('user_name', 'Doctor')
    if db is not None:
        req_ref = db.collection('accessRequests').document()
        req_ref.set({
            'doctorId': doctor_id,
            'doctorName': doctor_name,
            'patientId': patient_id,
            'status': 'pending',
            'createdAt': datetime.now()
        })
        flash('Medical records access request sent to patient.', 'success')
    return redirect(url_for('doctor_patients'))

@app.route('/doctor/earnings')
@doctor_required
def doctor_earnings():
    doctor_id = session.get('user_id')
    user_email = session.get('user_email')
    user_name = session.get('user_name', '')
    
    paid_patients_list = []
    total_revenue = 0.0
    online_revenue = 0.0
    in_person_revenue = 0.0
    
    if db is not None:
        try:
            docs = list(db.collection('appointments').stream())
            for d in docs:
                data = d.to_dict()
                data['id'] = d.id
                
                doc_id_match = (
                    (data.get('doctorId') == doctor_id) or
                    (user_email and data.get('doctorEmail') == user_email) or
                    (user_email and data.get('doctorId') == user_email) or
                    (user_name and data.get('doctorName', '').lower() in user_name.lower()) or
                    (session.get('user_role') == 'admin')
                )
                
                if doc_id_match:
                    status = data.get('status', 'pending')
                    payment_status = (data.get('paymentStatus') or '').lower()
                    payment_method = data.get('paymentMethod') or data.get('paymentType') or 'In-Person Cash'
                    fee = float(data.get('fee') or data.get('consultationFee') or 500)
                    
                    is_paid = (
                        status == 'completed' or
                        payment_status in ['paid', 'completed', 'success', 'pay_in_person', 'cash_on_visit', 'collected'] or
                        data.get('isPaid') == True
                    )
                    
                    if is_paid:
                        data['fee_earned'] = fee
                        data['payment_method_display'] = payment_method
                        
                        is_online = any(m in payment_method.lower() for m in ['bkash', 'nagad', 'card', 'online'])
                        if is_online:
                            online_revenue += fee
                            data['payment_badge_class'] = 'bg-primary text-white'
                            data['payment_label'] = f"Online ({payment_method})"
                        else:
                            in_person_revenue += fee
                            data['payment_badge_class'] = 'bg-success text-white'
                            data['payment_label'] = 'In-Person Cash'
                            
                        total_revenue += fee
                        paid_patients_list.append(data)
        except Exception as e:
            print(f"Error fetching doctor earnings: {e}")
            
    total_paid_patients = len(paid_patients_list)
    avg_fee = round(total_revenue / total_paid_patients, 2) if total_paid_patients > 0 else 0
    
    return render_template('doctor/earnings.html',
                           active_page='earnings',
                           completed_list=paid_patients_list,
                           total_revenue=total_revenue,
                           online_revenue=online_revenue,
                           in_person_revenue=in_person_revenue,
                           total_completed=total_paid_patients,
                           avg_fee=avg_fee)

@app.route('/doctor/profile', methods=['GET', 'POST'])
@doctor_required
def doctor_profile():
    doctor_id = session.get('user_id')
    doctor_data = {}
    if db is not None and doctor_id:
        doc_ref = db.collection('doctors').document(doctor_id)
        if request.method == 'POST':
            name = request.form.get('name')
            specialization = request.form.get('specialization')
            qualifications = request.form.get('qualifications')
            bmdcNumber = request.form.get('bmdcNumber')
            experience = int(request.form.get('experience', 5))
            consultationFee = float(request.form.get('consultationFee', 500))
            phone = request.form.get('phone')
            bio = request.form.get('bio')
            
            payload = {
                'name': name,
                'specialization': specialization,
                'qualifications': qualifications,
                'bmdcNumber': bmdcNumber,
                'experience': experience,
                'consultationFee': consultationFee,
                'phone': phone,
                'bio': bio,
                'updatedAt': datetime.now()
            }
            doc_ref.set(payload, merge=True)
            
            # Sync to users collection
            try:
                db.collection('users').document(doctor_id).set({
                    'name': name,
                    'specialization': specialization,
                    'qualifications': qualifications,
                    'bmdcNumber': bmdcNumber,
                    'consultationFee': consultationFee,
                    'phone': phone,
                    'updatedAt': datetime.now()
                }, merge=True)
            except Exception as sync_err:
                print(f"User sync error: {sync_err}")

            session['user_name'] = name
            flash('Doctor profile & fee updated successfully across database!', 'success')
            return redirect(url_for('doctor_profile'))
            
        doc = doc_ref.get()
        if doc.exists:
            doctor_data = doc.to_dict()
    return render_template('doctor/profile.html', active_page='profile', doctor_data=doctor_data)


def is_booking_for_diagnostic(booking_data, centre_id, user_email, user_name):
    """Check if a lab test booking belongs to the specified diagnostic centre"""
    if not booking_data or not isinstance(booking_data, dict):
        return False
        
    c_id = str(booking_data.get('diagnosticCentreId') or booking_data.get('diagnosticId') or booking_data.get('centreId') or '').strip()
    c_email = str(booking_data.get('diagnosticEmail') or booking_data.get('centreEmail') or '').lower().strip()
    c_name = str(booking_data.get('diagnosticCentreName') or booking_data.get('centreName') or '').lower().strip()
    
    target_id = str(centre_id or '').strip()
    target_email = str(user_email or '').lower().strip()
    target_name = str(user_name or '').lower().strip()
    
    # 1. Match by Exact Centre ID
    if target_id and c_id and c_id == target_id:
        return True
        
    # 2. Match by Centre Email
    if target_email and (c_email == target_email or c_id == target_email):
        return True
        
    # 3. Match by Centre Name
    if target_name and c_name and len(target_name) >= 3:
        if target_name in c_name or c_name in target_name:
            return True
            
    return False

# =================== Diagnostic Centre Web Portal Routes ===================

@app.route('/diagnostic/dashboard')
@diagnostic_required
def diagnostic_dashboard():
    centre_id = session.get('user_id')
    user_email = session.get('user_email')
    user_name = session.get('user_name', '')
    
    recent_bookings = []
    total_count = 0
    pending_count = 0
    transit_count = 0
    completed_count = 0

    if db is not None:
        try:
            docs = list(db.collection('lab_test_bookings').stream())
            for d in docs:
                data = d.to_dict()
                data['id'] = d.id
                
                if is_booking_for_diagnostic(data, centre_id, user_email, user_name):
                    recent_bookings.append(data)
                    total_count += 1
                    status = data.get('status')
                    if status == 'pending':
                        pending_count += 1
                    elif status in ['collectorAssigned', 'sampleCollected', 'processing']:
                        transit_count += 1
                    elif status == 'completed':
                        completed_count += 1
        except Exception as e:
            print(f"Error fetching lab test bookings: {e}")

    return render_template('diagnostic/dashboard.html',
                           active_page='dashboard',
                           recent_bookings=recent_bookings[:10],
                           total_count=total_count,
                           pending_count=pending_count,
                           transit_count=transit_count,
                           completed_count=completed_count)

@app.route('/diagnostic/bookings')
@diagnostic_required
def diagnostic_bookings():
    status_filter = request.args.get('status', '').strip().lower()
    centre_id = session.get('user_id')
    user_email = session.get('user_email')
    user_name = session.get('user_name', '')
    
    bookings = []
    stats = {'total': 0, 'pending': 0, 'approved': 0, 'processing': 0, 'completed': 0}

    if db is not None:
        try:
            docs = list(db.collection('lab_test_bookings').stream())
            for d in docs:
                data = d.to_dict()
                data['id'] = d.id
                
                if is_booking_for_diagnostic(data, centre_id, user_email, user_name):
                    status = (data.get('status') or 'pending').lower()
                    stats['total'] += 1
                    if status in stats:
                        stats[status] += 1
                    elif status in ['collectorassigned', 'samplecollected', 'processing']:
                        stats['processing'] += 1

                    if status_filter:
                        if status == status_filter:
                            bookings.append(data)
                    else:
                        bookings.append(data)
        except Exception as e:
            print(f"Error fetching lab test bookings: {e}")

    return render_template('diagnostic/bookings.html',
                           active_page='bookings',
                           bookings=bookings,
                           current_status=status_filter,
                           stats=stats)

@app.route('/diagnostic/booking/<booking_id>')
@diagnostic_required
def diagnostic_booking_detail(booking_id):
    booking = {'id': booking_id, 'patientName': 'Patient', 'status': 'pending'}
    if db is not None:
        try:
            doc = db.collection('lab_test_bookings').document(booking_id).get()
            if doc.exists:
                booking = doc.to_dict()
                booking['id'] = doc.id
        except Exception as e:
            print(f"Error fetching booking: {e}")

    return render_template('diagnostic/booking_detail.html',
                           active_page='bookings',
                           booking=booking)

@app.route('/diagnostic/booking/<booking_id>/status', methods=['POST'])
@diagnostic_required
def diagnostic_update_booking_status(booking_id):
    status = request.form.get('status')
    collectorName = request.form.get('collectorName')
    collectorPhone = request.form.get('collectorPhone')

    if db is not None:
        try:
            payload = {
                'status': status,
                'updatedAt': datetime.now().strftime('%Y-%m-%d %H:%M')
            }
            if collectorName:
                payload['collectorName'] = collectorName
            if collectorPhone:
                payload['collectorPhone'] = collectorPhone

            db.collection('lab_test_bookings').document(booking_id).update(payload)
            flash('Booking status updated successfully!', 'success')
        except Exception as e:
            flash(f'Error updating booking: {e}', 'danger')

    return redirect(url_for('diagnostic_booking_detail', booking_id=booking_id))

@app.route('/diagnostic/booking/<booking_id>/results', methods=['POST'])
@diagnostic_required
def diagnostic_save_test_results(booking_id):
    testResults = request.form.get('testResults')
    if db is not None:
        try:
            db.collection('lab_test_bookings').document(booking_id).update({
                'testResults': testResults,
                'status': 'completed',
                'updatedAt': datetime.now().strftime('%Y-%m-%d %H:%M')
            })
            flash('Test results saved and report published!', 'success')
        except Exception as e:
            flash(f'Error saving test results: {e}', 'danger')

    return redirect(url_for('diagnostic_booking_detail', booking_id=booking_id))

@app.route('/diagnostic/report/print/<booking_id>')
@diagnostic_required
def diagnostic_report_print(booking_id):
    booking = {'id': booking_id, 'patientName': 'Patient'}
    centre_info = {'name': session.get('user_name', 'Diagnostic Centre')}
    if db is not None:
        try:
            doc = db.collection('lab_test_bookings').document(booking_id).get()
            if doc.exists:
                booking = doc.to_dict()
                booking['id'] = doc.id
            c_doc = db.collection('diagnostic_centres').document(session.get('user_id', '')).get()
            if c_doc.exists:
                centre_info = c_doc.to_dict()
        except Exception as e:
            print(f"Error fetching report: {e}")

    return render_template('diagnostic/report_print.html', booking=booking, centre=centre_info)

@app.route('/diagnostic/catalog')
@diagnostic_required
def diagnostic_catalog():
    centre_id = session.get('user_id')
    tests = []
    if db is not None:
        try:
            # Check centre's own tests array first
            if centre_id:
                c_doc = db.collection('diagnostic_centres').document(centre_id).get()
                if c_doc.exists:
                    c_tests = c_doc.to_dict().get('tests', [])
                    for t in c_tests:
                        if isinstance(t, dict):
                            t['id'] = t.get('testId', t.get('name'))
                            t['name'] = t.get('testName', t.get('name'))
                            t['turnaroundTime'] = t.get('reportDeliveryTime', t.get('turnaroundTime', '24 Hours'))
                            tests.append(t)
            
            # Also stream available_lab_tests
            docs = db.collection('available_lab_tests').stream()
            for d in docs:
                data = d.to_dict()
                data['id'] = d.id
                if not any(x.get('name') == data.get('name') for x in tests):
                    tests.append(data)
        except Exception as e:
            print(f"Error fetching test catalog: {e}")

    return render_template('diagnostic/catalog.html', active_page='catalog', tests=tests)

@app.route('/diagnostic/catalog/add', methods=['POST'])
@diagnostic_required
def diagnostic_add_test():
    centre_id = session.get('user_id')
    name = request.form.get('name')
    category = request.form.get('category')
    price = float(request.form.get('price', 500))
    preparation = request.form.get('preparation')
    turnaroundTime = request.form.get('turnaroundTime') or '24 Hours'

    if db is not None:
        try:
            ref = db.collection('available_lab_tests').document()
            test_id = ref.id
            test_data = {
                'testId': test_id,
                'testName': name,
                'name': name,
                'category': category,
                'price': price,
                'preparation': preparation,
                'description': preparation,
                'preparationInstructions': preparation,
                'turnaroundTime': turnaroundTime,
                'reportDeliveryTime': turnaroundTime,
                'isAvailable': True,
                'centreId': centre_id,
                'createdAt': datetime.now()
            }
            ref.set(test_data)

            # Sync to diagnostic_centres/{centre_id} tests array for patient app
            if centre_id:
                diag_ref = db.collection('diagnostic_centres').document(centre_id)
                diag_doc = diag_ref.get()
                if diag_doc.exists:
                    current_tests = diag_doc.to_dict().get('tests', [])
                    current_tests.append({
                        'testId': test_id,
                        'testName': name,
                        'category': category,
                        'price': price,
                        'description': preparation,
                        'preparationInstructions': preparation,
                        'reportDeliveryTime': turnaroundTime
                    })
                    diag_ref.update({'tests': current_tests})

            flash('Test added to catalog & synced with Patient app!', 'success')
        except Exception as e:
            flash(f'Error adding test: {e}', 'danger')

    return redirect(url_for('diagnostic_catalog'))

@app.route('/diagnostic/catalog/delete/<test_id>')
@diagnostic_required
def diagnostic_delete_test(test_id):
    centre_id = session.get('user_id')
    if db is not None:
        try:
            db.collection('available_lab_tests').document(test_id).delete()
            if centre_id:
                diag_ref = db.collection('diagnostic_centres').document(centre_id)
                diag_doc = diag_ref.get()
                if diag_doc.exists:
                    current_tests = diag_doc.to_dict().get('tests', [])
                    updated_tests = [t for t in current_tests if t.get('testId') != test_id and t.get('name') != test_id]
                    diag_ref.update({'tests': updated_tests})
            flash('Test removed from catalog.', 'info')
        except Exception as e:
            flash(f'Error deleting test: {e}', 'danger')

    return redirect(url_for('diagnostic_catalog'))

@app.route('/diagnostic/patients')
@diagnostic_required
def diagnostic_patients():
    centre_id = session.get('user_id')
    user_email = session.get('user_email')
    user_name = session.get('user_name', '')
    search_query = request.args.get('search', '').strip().lower()
    
    diagnostic_patient_ids = set()
    diagnostic_patient_emails = set()
    
    if db is not None:
        try:
            booking_docs = list(db.collection('lab_test_bookings').stream())
            for d in booking_docs:
                data = d.to_dict()
                if is_booking_for_diagnostic(data, centre_id, user_email, user_name):
                    pid = data.get('patientId')
                    pemail = data.get('patientEmail')
                    if pid:
                        diagnostic_patient_ids.add(pid)
                    if pemail:
                        diagnostic_patient_emails.add(pemail.lower())
        except Exception as e:
            print(f"Error fetching diagnostic patient IDs: {e}")
            
    patients = []
    if db is not None and (diagnostic_patient_ids or diagnostic_patient_emails):
        try:
            all_patients = list(db.collection('users').where('role', '==', 'patient').stream())
            for pdoc in all_patients:
                pdata = pdoc.to_dict()
                pid = pdoc.id
                pemail = (pdata.get('email') or '').lower()
                
                if pid in diagnostic_patient_ids or (pemail and pemail in diagnostic_patient_emails):
                    pdata['id'] = pid
                    if search_query:
                        if (search_query in pdata.get('name', '').lower() or
                            search_query in pdata.get('phone', '').lower() or
                            search_query in pemail):
                            patients.append(pdata)
                    else:
                        patients.append(pdata)
        except Exception as e:
            print(f"Error fetching patient records: {e}")
            
    return render_template('diagnostic/patients.html', active_page='patients', patients=patients, search_query=search_query)

@app.route('/diagnostic/profile', methods=['GET', 'POST'])
@diagnostic_required
def diagnostic_profile():
    centre_id = session.get('user_id')
    centre_data = {}

    if db is not None and centre_id:
        doc_ref = db.collection('diagnostic_centres').document(centre_id)
        if request.method == 'POST':
            name = request.form.get('name')
            phone = request.form.get('phone')
            city = request.form.get('city')
            address = request.form.get('address')
            operatingHours = request.form.get('operatingHours')
            homeCollectionFee = float(request.form.get('homeCollectionFee', 100))
            isEmergencyAvailable = request.form.get('isEmergencyAvailable') == 'true'

            payload = {
                'name': name,
                'phone': phone,
                'city': city,
                'address': address,
                'operatingHours': operatingHours,
                'homeCollectionFee': homeCollectionFee,
                'isEmergencyAvailable': isEmergencyAvailable,
                'updatedAt': datetime.now()
            }
            doc_ref.set(payload, merge=True)
            session['user_name'] = name
            flash('Diagnostic centre profile updated!', 'success')
            return redirect(url_for('diagnostic_profile'))

        doc = doc_ref.get()
        if doc.exists:
            centre_data = doc.to_dict()

    return render_template('diagnostic/profile.html', active_page='profile', centre_data=centre_data)

@app.route('/doctor/favorites')
@doctor_required
def doctor_favorites():
    doctor_id = session.get('user_id')
    favorites = []
    if db is not None and doctor_id:
        doc = db.collection('doctors').document(doctor_id).get()
        if doc.exists:
            favorites = doc.to_dict().get('favoriteMedicines', [])
    return render_template('doctor/favorites.html', active_page='favorites', favorites=favorites)

@app.route('/doctor/favorites/add', methods=['POST'])
@doctor_required
def doctor_add_favorite_medicine():
    doctor_id = session.get('user_id')
    if db is not None and doctor_id:
        name = request.form.get('name')
        generic = request.form.get('generic')
        dosage = request.form.get('dosage')
        frequency = request.form.get('frequency')
        instruction = request.form.get('instruction')

        new_fav = {
            'name': name,
            'generic': generic,
            'dosage': dosage,
            'frequency': frequency,
            'instruction': instruction
        }

        doc_ref = db.collection('doctors').document(doctor_id)
        doc = doc_ref.get()
        current_favs = doc.to_dict().get('favoriteMedicines', []) if doc.exists else []
        current_favs.append(new_fav)
        doc_ref.set({'favoriteMedicines': current_favs}, merge=True)
        flash('Favorite medicine template saved!', 'success')
    return redirect(url_for('doctor_favorites'))

@app.route('/doctor/favorites/delete/<int:index>')
@doctor_required
def doctor_delete_favorite_medicine(index):
    doctor_id = session.get('user_id')
    if db is not None and doctor_id:
        doc_ref = db.collection('doctors').document(doctor_id)
        doc = doc_ref.get()
        if doc.exists:
            favs = doc.to_dict().get('favoriteMedicines', [])
            if 0 <= index < len(favs):
                favs.pop(index)
                doc_ref.set({'favoriteMedicines': favs}, merge=True)
                flash('Favorite medicine template removed.', 'info')
    return redirect(url_for('doctor_favorites'))

@app.route('/doctor/referrals')
@doctor_required
def doctor_referrals():
    doctor_id = session.get('user_id')
    referrals = []
    if db is not None:
        docs = db.collection('referrals').stream()
        for d in docs:
            data = d.to_dict()
            data['id'] = d.id
            if data.get('referringDoctorId') == doctor_id or session.get('user_role') == 'admin':
                referrals.append(data)
    return render_template('doctor/referrals.html', active_page='referrals', referrals=referrals)

@app.route('/doctor/referrals/create', methods=['POST'])
@doctor_required
def doctor_create_referral():
    doctor_id = session.get('user_id')
    doctor_name = session.get('user_name', 'Doctor')

    patientName = request.form.get('patientName')
    targetSpecialty = request.form.get('targetSpecialty')
    targetDoctorName = request.form.get('targetDoctorName')
    urgency = request.form.get('urgency')
    notes = request.form.get('notes')

    if db is not None:
        ref_doc = db.collection('referrals').document()
        ref_doc.set({
            'referringDoctorId': doctor_id,
            'referringDoctorName': doctor_name,
            'patientName': patientName,
            'targetSpecialty': targetSpecialty,
            'targetDoctorName': targetDoctorName,
            'urgency': urgency,
            'notes': notes,
            'date': datetime.now().strftime('%Y-%m-%d'),
            'createdAt': datetime.now()
        })
        flash('Patient referral issued successfully!', 'success')
    return redirect(url_for('doctor_referrals'))

# =================== Diagnostic Centre Staff Routes ===================

@app.route('/diagnostic/collectors')
@diagnostic_required
def diagnostic_collectors():
    centre_id = session.get('user_id')
    collectors = []
    if db is not None and centre_id:
        doc = db.collection('diagnostic_centres').document(centre_id).get()
        if doc.exists:
            collectors = doc.to_dict().get('collectors', [])
    return render_template('diagnostic/collectors.html', active_page='collectors', collectors=collectors)

@app.route('/diagnostic/collectors/add', methods=['POST'])
@diagnostic_required
def diagnostic_add_collector():
    centre_id = session.get('user_id')
    name = request.form.get('name')
    phone = request.form.get('phone')
    area = request.form.get('area')

    if db is not None and centre_id:
        doc_ref = db.collection('diagnostic_centres').document(centre_id)
        doc = doc_ref.get()
        current_cols = doc.to_dict().get('collectors', []) if doc.exists else []
        current_cols.append({'name': name, 'phone': phone, 'area': area, 'active': True})
        doc_ref.set({'collectors': current_cols}, merge=True)
        flash('Collector staff added successfully!', 'success')
    return redirect(url_for('diagnostic_collectors'))

@app.route('/diagnostic/collectors/delete/<int:index>')
@diagnostic_required
def diagnostic_delete_collector(index):
    centre_id = session.get('user_id')
    if db is not None and centre_id:
        doc_ref = db.collection('diagnostic_centres').document(centre_id)
        doc = doc_ref.get()
        if doc.exists:
            cols = doc.to_dict().get('collectors', [])
            if 0 <= index < len(cols):
                cols.pop(index)
                doc_ref.set({'collectors': cols}, merge=True)
                flash('Collector staff member removed.', 'info')
    return redirect(url_for('diagnostic_collectors'))

# =================== Admin Articles Management Routes ===================

@app.route('/admin/articles')
@login_required
def admin_articles():
    if session.get('user_role') != 'admin':
        flash('Unauthorized access.', 'danger')
        return redirect(url_for('login'))
        
    status_filter = request.args.get('status', '')
    search_query = request.args.get('search', '').strip().lower()
    
    articles = []
    stats = {'total': 0, 'published': 0, 'restricted': 0, 'draft': 0}
    
    if db is not None:
        try:
            docs = list(db.collection('health_articles').stream())
            for d in docs:
                data = d.to_dict()
                data['id'] = d.id
                
                is_pub = data.get('isPublished', True)
                status = data.get('status', 'published' if is_pub else 'restricted')
                if not is_pub and status != 'draft':
                    status = 'restricted'
                data['status'] = status
                
                # Stats calculation
                stats['total'] += 1
                if status == 'published':
                    stats['published'] += 1
                elif status == 'restricted':
                    stats['restricted'] += 1
                elif status == 'draft':
                    stats['draft'] += 1
                    
                # Search & status filtering
                matches_status = not status_filter or status == status_filter
                matches_search = not search_query or (
                    search_query in (data.get('title') or '').lower() or
                    search_query in (data.get('authorName') or data.get('doctorName') or '').lower()
                )
                
                if matches_status and matches_search:
                    articles.append(data)
        except Exception as e:
            print(f"Error fetching articles: {e}")
            
    return render_template('articles.html',
                           articles=articles,
                           stats=stats,
                           current_status=status_filter,
                           search_query=search_query)

@app.route('/admin/article/edit/<article_id>')
@login_required
def admin_edit_article(article_id):
    if session.get('user_role') != 'admin':
        flash('Unauthorized access.', 'danger')
        return redirect(url_for('login'))
        
    article = {'id': article_id, 'title': '', 'category': 'General Health', 'content': ''}
    if db is not None:
        try:
            doc = db.collection('health_articles').document(article_id).get()
            if doc.exists:
                article = doc.to_dict()
                article['id'] = doc.id
        except Exception as e:
            flash(f"Error fetching article: {e}", "danger")
            
    return render_template('edit_article.html', article=article)

@app.route('/admin/article/save/<article_id>', methods=['POST'])
@login_required
def admin_save_article(article_id):
    if session.get('user_role') != 'admin':
        flash('Unauthorized access.', 'danger')
        return redirect(url_for('login'))
        
    title = request.form.get('title')
    category = request.form.get('category')
    summary = request.form.get('summary')
    imageUrl = request.form.get('imageUrl')
    content = request.form.get('content')
    status = request.form.get('status', 'published')
    isFeatured = request.form.get('isFeatured') == 'true'
    
    isPublished = (status == 'published')
    
    if db is not None:
        try:
            db.collection('health_articles').document(article_id).set({
                'title': title,
                'category': category,
                'summary': summary,
                'imageUrl': imageUrl,
                'content': content,
                'body': content,
                'status': status,
                'isPublished': isPublished,
                'isFeatured': isFeatured,
                'updatedAt': datetime.now()
            }, merge=True)
            flash('Article changes saved successfully!', 'success')
        except Exception as e:
            flash(f'Error saving article: {e}', 'danger')
            
    return redirect(url_for('admin_articles'))

@app.route('/admin/article/<article_id>/<action>')
@login_required
def admin_update_article_status(article_id, action):
    if session.get('user_role') != 'admin':
        flash('Unauthorized access.', 'danger')
        return redirect(url_for('login'))
        
    if db is not None:
        try:
            doc_ref = db.collection('health_articles').document(article_id)
            if action == 'restrict':
                doc_ref.update({
                    'status': 'restricted',
                    'isPublished': False,
                    'restrictedAt': datetime.now()
                })
                try:
                    db.collection('articles').document(article_id).update({
                        'status': 'restricted',
                        'isPublished': False
                    })
                except Exception:
                    pass
                flash('Article restricted and blocked from patient view.', 'warning')
            elif action == 'approve':
                doc_ref.update({
                    'status': 'published',
                    'isPublished': True,
                    'approvedAt': datetime.now()
                })
                try:
                    db.collection('articles').document(article_id).update({
                        'status': 'published',
                        'isPublished': True
                    })
                except Exception:
                    pass
                flash('Article approved and published live for patients!', 'success')
            elif action == 'delete':
                doc_ref.delete()
                try:
                    db.collection('articles').document(article_id).delete()
                except Exception:
                    pass
                flash('Article deleted permanently from database.', 'info')
        except Exception as e:
            flash(f'Error updating article: {e}', 'danger')
            
    return redirect(url_for('admin_articles'))


# =================== Patient Auth & Decorator ===================

def patient_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        role = session.get('user_role')
        if role == 'admin':
            flash('Access restricted to Patients. You are logged in as Super Admin.', 'warning')
            return redirect(url_for('dashboard'))
            
        if 'user_email' not in session or role != 'patient':
            flash('Please login with your Patient account to access Patient Portal', 'warning')
            return redirect(url_for('login'))
            
        return f(*args, **kwargs)
    return decorated_function


# =================== Patient Web Portal Routes ===================

@app.route('/patient/dashboard')
@patient_required
def patient_dashboard():
    patient_id = session.get('user_id')
    user_email = session.get('user_email')
    
    appointments = []
    upcoming_count = 0
    prescriptions_count = 0
    lab_orders_count = 0
    total_visits = 0

    if db is not None:
        try:
            # Fetch appointments
            docs = list(db.collection('appointments').stream())
            for d in docs:
                data = d.to_dict()
                data['id'] = d.id
                p_id = data.get('patientId', '')
                p_email = data.get('patientEmail', '')
                
                if p_id == patient_id or p_email == user_email or patient_id == 'demo_patient_id':
                    data = update_appointment_status_if_overdue(data)
                    appointments.append(data)
                    st = data.get('status', 'pending')
                    if st in ['pending', 'confirmed', 'upcoming']:
                        upcoming_count += 1
                    if st == 'completed':
                        total_visits += 1
                    if data.get('prescription') or data.get('prescriptionId'):
                        prescriptions_count += 1
                        
            # Fetch lab test bookings
            lab_docs = list(db.collection('lab_test_bookings').stream())
            for d in lab_docs:
                data = d.to_dict()
                p_id = data.get('patientId', '')
                p_email = data.get('patientEmail', '')
                if p_id == patient_id or p_email == user_email or patient_id == 'demo_patient_id':
                    lab_orders_count += 1

            appointments.sort(key=lambda x: str(x.get('createdAt', '')), reverse=True)
        except Exception as e:
            print(f"Error fetching patient dashboard data: {e}")

    stats = {
        'upcoming_appointments': upcoming_count,
        'total_prescriptions': prescriptions_count,
        'lab_test_orders': lab_orders_count,
        'total_visits': total_visits
    }

    return render_template('patient/dashboard.html', active_page='dashboard', stats=stats, appointments=appointments)


@app.route('/patient/doctors')
@patient_required
def patient_find_doctors():
    search_query = request.args.get('search', '').strip()
    selected_spec = request.args.get('specialization', '').strip()
    
    doctors_list = []
    specializations = set()

    if db is not None:
        try:
            docs = list(db.collection('doctors').stream())
            for d in docs:
                data = d.to_dict()
                data['id'] = d.id
                v_status = data.get('verificationStatus', 'approved')
                spec = data.get('specialization', 'General')
                specializations.add(spec)
                
                if v_status == 'approved':
                    name = data.get('name', '').lower()
                    hosp = data.get('workplaceHospital', '').lower()
                    
                    matches_search = not search_query or search_query.lower() in name or search_query.lower() in spec.lower() or search_query.lower() in hosp
                    matches_spec = not selected_spec or spec.lower() == selected_spec.lower()
                    
                    if matches_search and matches_spec:
                        doctors_list.append(data)
        except Exception as e:
            print(f"Error fetching doctors list: {e}")

    spec_list = sorted(list(specializations))
    return render_template('patient/find_doctors.html', active_page='doctors', doctors=doctors_list, specializations=spec_list, search_query=search_query, selected_spec=selected_spec)


@app.route('/patient/doctor/<doctor_id>')
@patient_required
def patient_doctor_profile(doctor_id):
    doctor = None
    chambers = []
    availability = None

    if db is not None:
        try:
            doc_ref = db.collection('doctors').document(doctor_id).get()
            if doc_ref.exists:
                doctor = doc_ref.to_dict()
                doctor['id'] = doc_ref.id
                chambers = doctor.get('chambers', [])
                
                # Check top-level chambers collection too
                c_docs = db.collection('chambers').where('doctorId', '==', doctor_id).stream()
                for c in c_docs:
                    c_data = c.to_dict()
                    if not any(x.get('name') == c_data.get('name') for x in chambers):
                        chambers.append(c_data)
                        
                availability = doctor.get('availability')
        except Exception as e:
            print(f"Error fetching doctor profile: {e}")

    if not doctor:
        flash('Doctor not found.', 'warning')
        return redirect(url_for('patient_find_doctors'))

    return render_template('patient/doctor_profile.html', active_page='doctors', doctor=doctor, chambers=chambers, availability=availability)


@app.route('/patient/book/<doctor_id>', methods=['GET', 'POST'])
@patient_required
def patient_book_appointment(doctor_id):
    patient_id = session.get('user_id')
    patient_name = session.get('user_name', 'Patient')
    patient_email = session.get('user_email', '')

    doctor = None
    chambers = []
    time_slots = ['09:00 AM', '10:00 AM', '11:00 AM', '02:00 PM', '03:00 PM', '04:00 PM', '06:00 PM', '07:00 PM']

    if db is not None:
        try:
            doc_ref = db.collection('doctors').document(doctor_id).get()
            if doc_ref.exists:
                doctor = doc_ref.to_dict()
                doctor['id'] = doc_ref.id
                chambers = doctor.get('chambers', [])
                if doctor.get('generatedSlots'):
                    time_slots = doctor.get('generatedSlots')
        except Exception as e:
            print(f"Error loading doctor for booking: {e}")

    if not doctor:
        doctor = {'id': doctor_id, 'name': 'Specialist', 'specialization': 'General', 'consultationFee': 500}

    if request.method == 'POST':
        chamber = request.form.get('chamber', 'Main Chamber')
        appt_date = request.form.get('date')
        time_slot = request.form.get('time_slot')
        c_type = request.form.get('consultation_type', 'in_person')
        payment_method = request.form.get('payment_method', 'cash')
        symptoms = request.form.get('symptoms', '')
        fee = float(doctor.get('consultationFee', 500))

        if db is not None:
            try:
                appt_ref = db.collection('appointments').document()
                appt_data = {
                    'id': appt_ref.id,
                    'patientId': patient_id,
                    'patientName': patient_name,
                    'patientEmail': patient_email,
                    'doctorId': doctor_id,
                    'doctorName': doctor.get('name', 'Doctor'),
                    'specialization': doctor.get('specialization', 'General Practitioner'),
                    'hospital': doctor.get('workplaceHospital', 'MediConnect Hospital'),
                    'chamber': chamber,
                    'date': appt_date,
                    'timeSlot': time_slot,
                    'fee': fee,
                    'consultationType': c_type,
                    'paymentMethod': payment_method,
                    'paymentStatus': 'paid' if payment_method == 'online' else 'pending',
                    'status': 'pending',
                    'symptoms': symptoms,
                    'createdAt': datetime.now()
                }
                appt_ref.set(appt_data)
                flash(f'Appointment booked with Dr. {doctor.get("name")} for {appt_date} at {time_slot}!', 'success')
                return redirect(url_for('patient_appointments'))
            except Exception as e:
                flash(f'Booking error: {e}', 'danger')
        else:
            flash('Demo Mode: Appointment booked successfully!', 'success')
            return redirect(url_for('patient_appointments'))

    min_date = datetime.now().strftime('%Y-%m-%d')
    return render_template('patient/book_appointment.html', active_page='doctors', doctor=doctor, chambers=chambers, time_slots=time_slots, min_date=min_date)


@app.route('/patient/appointments')
@patient_required
def patient_appointments():
    patient_id = session.get('user_id')
    user_email = session.get('user_email')
    appointments = []

    if db is not None:
        try:
            docs = list(db.collection('appointments').stream())
            for d in docs:
                data = d.to_dict()
                data['id'] = d.id
                p_id = data.get('patientId', '')
                p_email = data.get('patientEmail', '')
                if p_id == patient_id or p_email == user_email or patient_id == 'demo_patient_id':
                    data = update_appointment_status_if_overdue(data)
                    appointments.append(data)
            appointments.sort(key=lambda x: str(x.get('createdAt', '')), reverse=True)
        except Exception as e:
            print(f"Error fetching patient appointments: {e}")

    return render_template('patient/appointments.html', active_page='appointments', appointments=appointments)


@app.route('/patient/appointment/<appointment_id>')
@patient_required
def patient_appointment_detail(appointment_id):
    appointment = None
    prescription = None

    if db is not None:
        try:
            a_doc = db.collection('appointments').document(appointment_id).get()
            if a_doc.exists:
                appointment = a_doc.to_dict()
                appointment['id'] = a_doc.id
                appointment = update_appointment_status_if_overdue(appointment)
                if appointment.get('prescription'):
                    prescription = appointment.get('prescription')
        except Exception as e:
            print(f"Error fetching appointment detail: {e}")

    if not appointment:
        flash('Appointment record not found.', 'warning')
        return redirect(url_for('patient_appointments'))

    return render_template('patient/appointment_detail.html', active_page='appointments', appointment=appointment, prescription=prescription)


@app.route('/patient/prescriptions')
@patient_required
def patient_prescriptions():
    patient_id = session.get('user_id')
    user_email = session.get('user_email')
    prescriptions = []

    if db is not None:
        try:
            docs = list(db.collection('appointments').stream())
            for d in docs:
                data = d.to_dict()
                p_id = data.get('patientId', '')
                p_email = data.get('patientEmail', '')
                if p_id == patient_id or p_email == user_email or patient_id == 'demo_patient_id':
                    if data.get('prescription'):
                        p_obj = data.get('prescription')
                        p_obj['appointmentId'] = d.id
                        p_obj['doctorName'] = data.get('doctorName')
                        p_obj['date'] = data.get('date')
                        p_obj['specialization'] = data.get('specialization')
                        prescriptions.append(p_obj)
        except Exception as e:
            print(f"Error fetching patient prescriptions: {e}")

    return render_template('patient/prescriptions.html', active_page='prescriptions', prescriptions=prescriptions)


@app.route('/patient/prescription/<appointment_id>/print')
@patient_required
def patient_prescription_print(appointment_id):
    appointment = None
    prescription = None

    if db is not None:
        try:
            a_doc = db.collection('appointments').document(appointment_id).get()
            if a_doc.exists:
                appointment = a_doc.to_dict()
                appointment['id'] = a_doc.id
                prescription = appointment.get('prescription', {})
        except Exception as e:
            print(f"Error fetching prescription print data: {e}")

    if not appointment:
        appointment = {'id': appointment_id, 'doctorName': 'Specialist Doctor', 'date': datetime.now().strftime('%Y-%m-%d')}
        prescription = {'medicines': [{'name': 'Paracetamol 500mg', 'dosage': '1-0-1', 'duration': '5 Days'}]}

    return render_template('patient/prescription_print.html', appointment=appointment, prescription=prescription)


@app.route('/patient/diagnostic-centres')
@patient_required
def patient_diagnostic_centres():
    search_query = request.args.get('search', '').strip()
    centres = []

    if db is not None:
        try:
            docs = list(db.collection('diagnostic_centres').stream())
            for d in docs:
                data = d.to_dict()
                data['id'] = d.id
                v_status = data.get('verificationStatus', 'approved')
                st = data.get('status', 'active')
                if v_status != 'rejected' and st != 'inactive':
                    name = data.get('name', '').lower()
                    city = data.get('city', '').lower()
                    if not search_query or search_query.lower() in name or search_query.lower() in city:
                        centres.append(data)
        except Exception as e:
            print(f"Error fetching diagnostic centres: {e}")

    if not centres:
        centres = [
            {
                'id': 'popular_diag_1',
                'name': 'Popular Diagnostic Centre',
                'address': 'House 16, Road 2, Dhanmondi',
                'city': 'Dhaka',
                'contactNumber': '+880 1712-345678',
                'rating': 4.8,
                'verificationStatus': 'approved',
                'dghsCode': 'DGHS-102941',
                'tests': [
                    {'id': 't1', 'testName': 'Complete Blood Count (CBC)', 'name': 'Complete Blood Count (CBC)', 'category': 'Blood Test', 'price': 450, 'reportDeliveryTime': '24 hours'},
                    {'id': 't2', 'testName': 'Blood Sugar (Fasting)', 'name': 'Blood Sugar (Fasting)', 'category': 'Blood Test', 'price': 200, 'reportDeliveryTime': '24 hours'},
                    {'id': 't3', 'testName': 'Lipid Profile', 'name': 'Lipid Profile', 'category': 'Blood Test', 'price': 1200, 'reportDeliveryTime': '24 hours'},
                    {'id': 't4', 'testName': 'X-Ray (Chest)', 'name': 'X-Ray (Chest)', 'category': 'Radiology', 'price': 800, 'reportDeliveryTime': '4 hours'}
                ]
            },
            {
                'id': 'ibn_sina_diag_2',
                'name': 'Ibn Sina Diagnostic',
                'address': 'House 48, Road 9/A, Dhanmondi',
                'city': 'Dhaka',
                'contactNumber': '+880 1812-345679',
                'rating': 4.7,
                'verificationStatus': 'approved',
                'dghsCode': 'DGHS-940122',
                'tests': [
                    {'id': 't11', 'testName': 'Thyroid Profile (T3, T4, TSH)', 'name': 'Thyroid Profile (T3, T4, TSH)', 'category': 'Blood Test', 'price': 1800, 'reportDeliveryTime': '24 hours'},
                    {'id': 't12', 'testName': 'HbA1c (Diabetes)', 'name': 'HbA1c (Diabetes)', 'category': 'Diabetes', 'price': 800, 'reportDeliveryTime': '24 hours'},
                    {'id': 't13', 'testName': 'Vitamin D (25-OH)', 'name': 'Vitamin D (25-OH)', 'category': 'Vitamin', 'price': 2500, 'reportDeliveryTime': '48 hours'}
                ]
            },
            {
                'id': 'labaid_diag_3',
                'name': 'Labaid Diagnostic',
                'address': 'House 1, Road 4, Dhanmondi',
                'city': 'Dhaka',
                'contactNumber': '+880 1912-345680',
                'rating': 4.9,
                'verificationStatus': 'approved',
                'dghsCode': 'DGHS-882103',
                'tests': [
                    {'id': 't17', 'testName': 'Kidney Function Test (KFT)', 'name': 'Kidney Function Test (KFT)', 'category': 'Blood Test', 'price': 1400, 'reportDeliveryTime': '24 hours'},
                    {'id': 't18', 'testName': 'Liver Function Test (LFT)', 'name': 'Liver Function Test (LFT)', 'category': 'Blood Test', 'price': 1500, 'reportDeliveryTime': '24 hours'},
                    {'id': 't19', 'testName': 'ECG (12-Lead)', 'name': 'ECG (12-Lead)', 'category': 'Cardiac', 'price': 500, 'reportDeliveryTime': '1 hour'}
                ]
            }
        ]

    return render_template('patient/diagnostic_centres.html', active_page='diagnostics', centres=centres, search_query=search_query)


def update_appointment_status_if_overdue(data):
    """If appointment date & time has passed and status is pending/confirmed/upcoming, evaluate as missed."""
    st = str(data.get('status', 'pending')).lower()
    if st in ['pending', 'confirmed', 'upcoming']:
        appt_date_str = data.get('date', '')
        time_slot = data.get('timeSlot', '')
        if appt_date_str:
            try:
                if 'T' in str(appt_date_str):
                    appt_date = datetime.fromisoformat(str(appt_date_str).replace('Z', '+00:00')).date()
                else:
                    appt_date = datetime.strptime(str(appt_date_str)[:10], '%Y-%m-%d').date()
                
                now = datetime.now()
                today = now.date()
                
                if appt_date < today:
                    data['status'] = 'missed'
                elif appt_date == today and time_slot:
                    parts = time_slot.split('-')
                    if len(parts) >= 2:
                        end_time_str = parts[1].strip()
                        try:
                            if 'PM' in end_time_str or 'AM' in end_time_str:
                                slot_end = datetime.strptime(end_time_str, '%I:%M %p').time()
                            else:
                                slot_end = datetime.strptime(end_time_str, '%H:%M').time()
                            if now.time() > slot_end:
                                data['status'] = 'missed'
                        except Exception:
                            pass
            except Exception as e:
                print(f"Error checking overdue appt status: {e}")
    return data


@app.route('/patient/diagnostic/<centre_id>')
@patient_required
def patient_diagnostic_detail(centre_id):
    centre = None
    tests = []

    if db is not None:
        try:
            c_doc = db.collection('diagnostic_centres').document(centre_id).get()
            if c_doc.exists:
                centre = c_doc.to_dict()
                centre['id'] = c_doc.id
                tests = centre.get('tests', [])
                
                t_docs = list(db.collection('available_lab_tests').where('centreId', '==', centre_id).stream())
                for t in t_docs:
                    t_data = t.to_dict()
                    t_data['id'] = t.id
                    if not any(x.get('testName') == t_data.get('testName') or x.get('name') == t_data.get('name') for x in tests):
                        tests.append(t_data)
        except Exception as e:
            print(f"Error fetching diagnostic detail: {e}")

    demo_centres = {
        'popular_diag_1': {
            'id': 'popular_diag_1',
            'name': 'Popular Diagnostic Centre',
            'address': 'House 16, Road 2, Dhanmondi',
            'city': 'Dhaka',
            'contactNumber': '+880 1712-345678',
            'dghsCode': 'DGHS-102941',
            'pathologistName': 'Dr. Farhana Ahmed',
            'pathologistBmdcNumber': 'A-49201',
            'tests': [
                {'id': 't1', 'testName': 'Complete Blood Count (CBC)', 'name': 'Complete Blood Count (CBC)', 'category': 'Blood Test', 'price': 450, 'reportDeliveryTime': '24 hours', 'preparation': 'No special preparation needed'},
                {'id': 't2', 'testName': 'Blood Sugar (Fasting)', 'name': 'Blood Sugar (Fasting)', 'category': 'Blood Test', 'price': 200, 'reportDeliveryTime': '24 hours', 'preparation': '8-10 hours overnight fasting'},
                {'id': 't3', 'testName': 'Lipid Profile', 'name': 'Lipid Profile', 'category': 'Blood Test', 'price': 1200, 'reportDeliveryTime': '24 hours', 'preparation': '12 hours fasting'},
                {'id': 't4', 'testName': 'X-Ray (Chest)', 'name': 'X-Ray (Chest)', 'category': 'Radiology', 'price': 800, 'reportDeliveryTime': '4 hours', 'preparation': 'Remove metal objects'}
            ]
        },
        'ibn_sina_diag_2': {
            'id': 'ibn_sina_diag_2',
            'name': 'Ibn Sina Diagnostic',
            'address': 'House 48, Road 9/A, Dhanmondi',
            'city': 'Dhaka',
            'contactNumber': '+880 1812-345679',
            'dghsCode': 'DGHS-940122',
            'pathologistName': 'Dr. Kamrul Hasan',
            'pathologistBmdcNumber': 'A-38192',
            'tests': [
                {'id': 't11', 'testName': 'Thyroid Profile (T3, T4, TSH)', 'name': 'Thyroid Profile (T3, T4, TSH)', 'category': 'Blood Test', 'price': 1800, 'reportDeliveryTime': '24 hours', 'preparation': 'No preparation needed'},
                {'id': 't12', 'testName': 'HbA1c (Diabetes)', 'name': 'HbA1c (Diabetes)', 'category': 'Diabetes', 'price': 800, 'reportDeliveryTime': '24 hours', 'preparation': 'Fasting not required'},
                {'id': 't13', 'testName': 'Vitamin D (25-OH)', 'name': 'Vitamin D (25-OH)', 'category': 'Vitamin', 'price': 2500, 'reportDeliveryTime': '48 hours', 'preparation': 'No preparation needed'}
            ]
        },
        'labaid_diag_3': {
            'id': 'labaid_diag_3',
            'name': 'Labaid Diagnostic',
            'address': 'House 1, Road 4, Dhanmondi',
            'city': 'Dhaka',
            'contactNumber': '+880 1912-345680',
            'dghsCode': 'DGHS-882103',
            'pathologistName': 'Dr. Subhash Bose',
            'pathologistBmdcNumber': 'A-51029',
            'tests': [
                {'id': 't17', 'testName': 'Kidney Function Test (KFT)', 'name': 'Kidney Function Test (KFT)', 'category': 'Blood Test', 'price': 1400, 'reportDeliveryTime': '24 hours', 'preparation': '8 hours fasting'},
                {'id': 't18', 'testName': 'Liver Function Test (LFT)', 'name': 'Liver Function Test (LFT)', 'category': 'Blood Test', 'price': 1500, 'reportDeliveryTime': '24 hours', 'preparation': '10 hours fasting'},
                {'id': 't19', 'testName': 'ECG (12-Lead)', 'name': 'ECG (12-Lead)', 'category': 'Cardiac', 'price': 500, 'reportDeliveryTime': '1 hour', 'preparation': 'No preparation needed'}
            ]
        }
    }

    if not centre:
        if centre_id in demo_centres:
            centre = demo_centres[centre_id]
            tests = centre.get('tests', [])
        else:
            centre = {
                'id': centre_id,
                'name': 'Diagnostic Centre',
                'address': 'Dhanmondi, Dhaka',
                'city': 'Dhaka',
                'contactNumber': '+880 1700-000000',
                'dghsCode': 'DGHS-900001',
                'pathologistName': 'Chief Pathologist',
                'pathologistBmdcNumber': 'A-10000'
            }

    min_date = datetime.now().strftime('%Y-%m-%d')
    return render_template('patient/diagnostic_detail.html', active_page='diagnostics', centre=centre, tests=tests, min_date=min_date)


@app.route('/patient/book-tests/<centre_id>', methods=['POST'])
@patient_required
def patient_book_lab_tests(centre_id):
    patient_id = session.get('user_id')
    patient_name = session.get('user_name', 'Patient')
    patient_email = session.get('user_email', '')

    test_id = request.form.get('test_id')
    test_name = request.form.get('test_name')
    test_category = request.form.get('test_category', 'General')
    test_price = float(request.form.get('test_price', 500))
    collection_type = request.form.get('collection_type', 'homeSample')
    scheduled_date = request.form.get('scheduled_date')
    time_slot = request.form.get('time_slot', '09:00 AM - 12:00 PM')
    address = request.form.get('address', '')
    payment_method = request.form.get('payment_method', 'manual')

    home_fee = 150.0 if collection_type == 'homeSample' else 0.0
    total_amount = test_price + home_fee

    centre_name = 'Diagnostic Centre'
    if db is not None:
        try:
            c_doc = db.collection('diagnostic_centres').document(centre_id).get()
            if c_doc.exists:
                centre_name = c_doc.to_dict().get('name', 'Diagnostic Centre')

            booking_ref = db.collection('lab_test_bookings').document()
            booking_data = {
                'id': booking_ref.id,
                'patientId': patient_id,
                'patientName': patient_name,
                'patientEmail': patient_email,
                'diagnosticCentreId': centre_id,
                'diagnosticCentreName': centre_name,
                'tests': [{
                    'testId': test_id,
                    'testName': test_name,
                    'category': test_category,
                    'price': test_price
                }],
                'status': 'pending',
                'collectionType': collection_type,
                'paymentMethod': payment_method,
                'paymentStatus': 'paid' if payment_method == 'online' else 'pending',
                'scheduledDate': scheduled_date,
                'timeSlot': time_slot,
                'address': address,
                'totalAmount': total_amount,
                'homeCollectionFee': home_fee,
                'createdAt': datetime.now()
            }
            booking_ref.set(booking_data)
            flash(f'Lab Test booking ({test_name}) submitted to {centre_name}!', 'success')
            return redirect(url_for('patient_lab_tests'))
        except Exception as e:
            flash(f'Booking error: {e}', 'danger')
    else:
        flash('Demo Mode: Lab test booking submitted!', 'success')
        return redirect(url_for('patient_lab_tests'))


@app.route('/patient/lab-tests')
@patient_required
def patient_lab_tests():
    patient_id = session.get('user_id')
    user_email = session.get('user_email')
    bookings = []

    if db is not None:
        try:
            docs = list(db.collection('lab_test_bookings').stream())
            for d in docs:
                data = d.to_dict()
                data['id'] = d.id
                p_id = data.get('patientId', '')
                p_email = data.get('patientEmail', '')
                if p_id == patient_id or p_email == user_email or patient_id == 'demo_patient_id':
                    bookings.append(data)
            bookings.sort(key=lambda x: str(x.get('createdAt', '')), reverse=True)
        except Exception as e:
            print(f"Error fetching patient lab test bookings: {e}")

    return render_template('patient/lab_tests.html', active_page='lab_tests', bookings=bookings)


@app.route('/patient/profile', methods=['GET', 'POST'])
@patient_required
def patient_profile():
    patient_id = session.get('user_id')
    profile = {}

    if db is not None:
        try:
            p_doc = db.collection('users').document(patient_id).get()
            if p_doc.exists:
                profile = p_doc.to_dict()
        except Exception as e:
            print(f"Error fetching patient profile: {e}")

    if request.method == 'POST':
        name = request.form.get('name')
        phone = request.form.get('phone')
        dob = request.form.get('dob')
        gender = request.form.get('gender')
        blood_group = request.form.get('blood_group')
        emergency_contact = request.form.get('emergency_contact')

        if db is not None:
            try:
                db.collection('users').document(patient_id).update({
                    'name': name,
                    'phone': phone,
                    'dob': dob,
                    'gender': gender,
                    'blood_group': blood_group,
                    'emergency_contact': emergency_contact
                })
                session['user_name'] = name
                flash('Profile updated successfully!', 'success')
                return redirect(url_for('patient_profile'))
            except Exception as e:
                flash(f'Update error: {e}', 'danger')
        else:
            session['user_name'] = name
            flash('Demo Mode: Profile updated!', 'success')
            return redirect(url_for('patient_profile'))

    return render_template('patient/profile.html', active_page='profile', profile=profile)


# =================== Error Handlers ===================

@app.errorhandler(404)
def not_found(e):
    if 'login' in request.url:
        return render_template('login.html'), 404
    if session.get('admin_email'):
        return redirect(url_for('index'))
    return redirect(url_for('login'))

@app.errorhandler(500)
def server_error(e):
    print(f'500 Error: {str(e)}')
    import traceback
    traceback.print_exc()
    flash(f'Server error: {str(e)}', 'danger')
    if session.get('admin_email'):
        return redirect(url_for('index'))
    return redirect(url_for('login'))

# =================== Main ===================

if __name__ == "__main__":
    print("=" * 60)
    print("MediConnect Unified Web Portals (Admin, Doctor, Diagnostic)")
    print("=" * 60)
    print("Starting Flask server...")
    print("Web Portals URL: http://localhost:5000")
    print("Admin: admin@mediconnect.com / admin123")
    print("Doctor Demo: doctor@mediconnect.com")
    print("Diagnostic Demo: diagnostic@mediconnect.com")
    print("=" * 60)
    app.run(debug=True, host="0.0.0.0", port=5000)
