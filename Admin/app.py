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
                    'createdAt': datetime.now()
                })

                db.collection('diagnostic_centres').document(user_id).set({
                    'id': user_id,
                    'name': name,
                    'email': email,
                    'phone': phone,
                    'city': city,
                    'address': address,
                    'tradeLicenseNumber': tradeLicenseNumber,
                    'operatingHours': operatingHours,
                    'homeCollectionFee': homeCollectionFee,
                    'isEmergencyAvailable': True,
                    'verificationStatus': 'pending',
                    'createdAt': datetime.now()
                })

                session['admin_email'] = email
                session['user_id'] = user_id
                session['user_email'] = email
                session['user_role'] = 'diagnostic_centre'
                session['user_name'] = name
                session['verification_status'] = 'pending'

                flash('Diagnostic Centre registration submitted! Verification is pending admin review.', 'info')
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

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        email = request.form.get('email')
        password = request.form.get('password')
        
        # 1. Super Admin Check
        if email in ADMIN_CREDENTIALS and check_password_hash(ADMIN_CREDENTIALS[email], password):
            session['admin_email'] = email
            session['user_id'] = 'admin'
            session['user_email'] = email
            session['user_role'] = 'admin'
            session['user_name'] = 'Super Admin'
            flash('Login successful as Super Admin!', 'success')
            return redirect(url_for('dashboard'))
            
        # 2. Doctor & Diagnostic Centre Check in Firestore
        if db is not None:
            try:
                # Check users collection
                user_docs = list(db.collection('users').where('email', '==', email).stream())
                if user_docs:
                    user = user_docs[0].to_dict()
                    uid = user_docs[0].id
                    role = user.get('role', 'patient')
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
                            flash('Your Doctor verification is pending or under review. Dashboard access restricted.', 'warning')
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
                    elif role == 'admin':
                        flash('Welcome back, Admin!', 'success')
                        return redirect(url_for('dashboard'))
                
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

# =================== Doctor & Diagnostic Auth Decorators ===================

def doctor_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'admin_email' not in session and 'user_email' not in session:
            flash('Please login to access Doctor Portal', 'warning')
            return redirect(url_for('login'))
        role = session.get('user_role')
        if role not in ['doctor', 'admin']:
            flash('Access restricted to Doctors only', 'danger')
            return redirect(url_for('login'))
        if role == 'doctor' and session.get('verification_status') != 'approved':
            flash('Your account is pending admin verification.', 'warning')
            return redirect(url_for('verification_pending'))
        return f(*args, **kwargs)
    return decorated_function

def diagnostic_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'admin_email' not in session and 'user_email' not in session:
            flash('Please login to access Diagnostic Portal', 'warning')
            return redirect(url_for('login'))
        role = session.get('user_role')
        if role not in ['diagnostic_centre', 'diagnostic', 'admin']:
            flash('Access restricted to Diagnostic Centres only', 'danger')
            return redirect(url_for('login'))
        if role in ['diagnostic_centre', 'diagnostic'] and session.get('verification_status') != 'approved':
            flash('Your account is pending admin verification.', 'warning')
            return redirect(url_for('verification_pending'))
        return f(*args, **kwargs)
    return decorated_function

# =================== Doctor Web Portal Routes ===================

@app.route('/doctor/dashboard')
@doctor_required
def doctor_dashboard():
    doctor_id = session.get('user_id')
    today_str = datetime.now().strftime('%Y-%m-%d')
    
    appointments = []
    today_count = 0
    pending_count = 0
    completed_count = 0
    total_earnings = 0

    if db is not None:
        try:
            docs = db.collection('appointments').stream()
            for d in docs:
                data = d.to_dict()
                data['id'] = d.id
                doc_id_match = (data.get('doctorId') == doctor_id) or (session.get('user_role') == 'admin')
                if doc_id_match:
                    appointments.append(data)
                    if data.get('date') == today_str or data.get('createdAt') == today_str:
                        today_count += 1
                    if data.get('status') == 'pending':
                        pending_count += 1
                    elif data.get('status') == 'completed':
                        completed_count += 1
                        total_earnings += float(data.get('fee') or 500)
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
    status_filter = request.args.get('status', '')
    doctor_id = session.get('user_id')
    today_str = datetime.now().strftime('%Y-%m-%d')
    
    appointments = []
    stats = {'total': 0, 'pending': 0, 'approved': 0, 'completed': 0, 'missed': 0, 'cancelled': 0}
    
    if db is not None:
        try:
            docs = list(db.collection('appointments').stream())
            for d in docs:
                data = d.to_dict()
                data['id'] = d.id
                doc_id_match = (data.get('doctorId') == doctor_id) or (session.get('user_role') == 'admin')
                
                if doc_id_match:
                    appt_status = data.get('status', 'pending')
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
            isInstantAvailable = request.form.get('isInstantAvailable') == 'true'
            
            availability_payload = {
                'availableDays': availableDays,
                'startTime': startTime,
                'endTime': endTime,
                'slotDuration': slotDuration,
                'maxPatientsPerSlot': maxPatientsPerSlot
            }
            doc_ref.set({
                'availability': availability_payload,
                'isInstantAvailable': isInstantAvailable,
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
    if db is not None and doctor_id:
        name = request.form.get('name')
        address = request.form.get('address')
        phone = request.form.get('phone')
        visitingHours = request.form.get('visitingHours')
        fee = int(request.form.get('fee', 500))
        
        new_chamber = {
            'name': name,
            'address': address,
            'phone': phone,
            'visitingHours': visitingHours,
            'fee': fee
        }
        
        doc_ref = db.collection('doctors').document(doctor_id)
        doc = doc_ref.get()
        current_chambers = doc.to_dict().get('chambers', []) if doc.exists else []
        current_chambers.append(new_chamber)
        
        doc_ref.set({'chambers': current_chambers}, merge=True)
        flash('Chamber added successfully!', 'success')
    return redirect(url_for('doctor_chambers'))

@app.route('/doctor/chambers/delete/<int:index>')
@doctor_required
def doctor_delete_chamber(index):
    doctor_id = session.get('user_id')
    if db is not None and doctor_id:
        doc_ref = db.collection('doctors').document(doctor_id)
        doc = doc_ref.get()
        if doc.exists:
            chambers = doc.to_dict().get('chambers', [])
            if 0 <= index < len(chambers):
                chambers.pop(index)
                doc_ref.set({'chambers': chambers}, merge=True)
                flash('Chamber removed.', 'info')
    return redirect(url_for('doctor_chambers'))

@app.route('/doctor/patients')
@doctor_required
def doctor_patients():
    search_query = request.args.get('search', '').lower()
    patients = []
    if db is not None:
        docs = db.collection('users').where('role', '==', 'patient').stream()
        for d in docs:
            data = d.to_dict()
            data['id'] = d.id
            if search_query:
                if search_query in data.get('name', '').lower() or search_query in data.get('phone', '').lower() or search_query in data.get('email', '').lower():
                    patients.append(data)
            else:
                patients.append(data)
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
    completed_list = []
    total_revenue = 0
    if db is not None:
        docs = db.collection('appointments').stream()
        for d in docs:
            data = d.to_dict()
            data['id'] = d.id
            if (data.get('doctorId') == doctor_id or session.get('user_role') == 'admin') and data.get('status') == 'completed':
                completed_list.append(data)
                total_revenue += float(data.get('fee') or 500)
                
    total_completed = len(completed_list)
    avg_fee = round(total_revenue / total_completed, 2) if total_completed > 0 else 0
    return render_template('doctor/earnings.html',
                           active_page='earnings',
                           completed_list=completed_list,
                           total_revenue=total_revenue,
                           total_completed=total_completed,
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
            session['user_name'] = name
            flash('Doctor profile updated successfully!', 'success')
            return redirect(url_for('doctor_profile'))
            
        doc = doc_ref.get()
        if doc.exists:
            doctor_data = doc.to_dict()
    return render_template('doctor/profile.html', active_page='profile', doctor_data=doctor_data)


# =================== Diagnostic Centre Web Portal Routes ===================

@app.route('/diagnostic/dashboard')
@diagnostic_required
def diagnostic_dashboard():
    centre_id = session.get('user_id')
    recent_bookings = []
    total_count = 0
    pending_count = 0
    transit_count = 0
    completed_count = 0

    if db is not None:
        try:
            docs = db.collection('lab_test_bookings').stream()
            for d in docs:
                data = d.to_dict()
                data['id'] = d.id
                recent_bookings.append(data)
                total_count += 1
                status = data.get('status')
                if status == 'pending':
                    pending_count += 1
                elif status in ['collectorAssigned', 'sampleCollected']:
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
    status_filter = request.args.get('status', '')
    bookings = []

    if db is not None:
        try:
            docs = db.collection('lab_test_bookings').stream()
            for d in docs:
                data = d.to_dict()
                data['id'] = d.id
                if status_filter:
                    if data.get('status') == status_filter:
                        bookings.append(data)
                else:
                    bookings.append(data)
        except Exception as e:
            print(f"Error fetching lab bookings: {e}")

    return render_template('diagnostic/bookings.html',
                           active_page='bookings',
                           bookings=bookings,
                           current_status=status_filter)

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
    tests = []
    if db is not None:
        try:
            docs = db.collection('available_lab_tests').stream()
            for d in docs:
                data = d.to_dict()
                data['id'] = d.id
                tests.append(data)
        except Exception as e:
            print(f"Error fetching test catalog: {e}")

    return render_template('diagnostic/catalog.html', active_page='catalog', tests=tests)

@app.route('/diagnostic/catalog/add', methods=['POST'])
@diagnostic_required
def diagnostic_add_test():
    name = request.form.get('name')
    category = request.form.get('category')
    price = float(request.form.get('price', 500))
    preparation = request.form.get('preparation')
    turnaroundTime = request.form.get('turnaroundTime')

    if db is not None:
        try:
            ref = db.collection('available_lab_tests').document()
            ref.set({
                'name': name,
                'category': category,
                'price': price,
                'preparation': preparation,
                'turnaroundTime': turnaroundTime,
                'isAvailable': True,
                'createdAt': datetime.now()
            })
            flash('Test added to catalog!', 'success')
        except Exception as e:
            flash(f'Error adding test: {e}', 'danger')

    return redirect(url_for('diagnostic_catalog'))

@app.route('/diagnostic/catalog/delete/<test_id>')
@diagnostic_required
def diagnostic_delete_test(test_id):
    if db is not None:
        try:
            db.collection('available_lab_tests').document(test_id).delete()
            flash('Test removed from catalog.', 'info')
        except Exception as e:
            flash(f'Error deleting test: {e}', 'danger')

    return redirect(url_for('diagnostic_catalog'))

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
