from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import firebase_admin
from firebase_admin import credentials, firestore, auth
from typing import Optional, List
from pydantic import BaseModel, EmailStr
from datetime import datetime
import os

# Initialize FastAPI app
app = FastAPI(
    title="MediConnect Admin API",
    description="Admin Panel Backend for MediConnect System",
    version="1.0.0"
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


cred = credentials.Certificate("serviceAccountKey.json")  
firebase_admin.initialize_app(cred)

# Firestore client
db = firestore.client()



class DoctorApproval(BaseModel):
    doctor_id: str
    approved: bool
    rejection_reason: Optional[str] = None

class Hospital(BaseModel):
    name: str
    address: str
    city: str
    phone: str
    email: EmailStr
    specialties: List[str]
    is_emergency_available: bool = False
    description: Optional[str] = None

class DoctorAssignment(BaseModel):
    doctor_id: str
    hospital_id: str

# =================== Helper Functions ===================

def verify_admin_token(authorization: str = None):
    """Verify admin token from request header"""
    if not authorization:
        raise HTTPException(status_code=401, detail="No authorization token provided")
    
    try:
        token = authorization.split("Bearer ")[1]
        decoded_token = auth.verify_id_token(token)
        user_id = decoded_token['uid']
        
        # Check if user is admin
        user_doc = db.collection('users').document(user_id).get()
        if not user_doc.exists or user_doc.to_dict().get('role') != 'admin':
            raise HTTPException(status_code=403, detail="Access denied. Admin only.")
        
        return user_id
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {str(e)}")

# =================== Routes ===================

@app.get("/")
async def root():
    return {
        "message": "MediConnect Admin API",
        "version": "1.0.0",
        "status": "active"
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}

# =================== Doctor Management ===================

@app.get("/api/doctors/pending")
async def get_pending_doctors():
    """Get all doctors pending approval"""
    try:
        doctors_ref = db.collection('users').where('role', '==', 'doctor').where('approved', '==', False)
        doctors = []
        
        for doc in doctors_ref.stream():
            doctor_data = doc.to_dict()
            doctor_data['id'] = doc.id
            doctors.append(doctor_data)
        
        return {"success": True, "data": doctors, "count": len(doctors)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/doctors/approve")
async def approve_doctor(approval: DoctorApproval):
    """Approve or reject a doctor"""
    try:
        doctor_ref = db.collection('users').document(approval.doctor_id)
        doctor = doctor_ref.get()
        
        if not doctor.exists:
            raise HTTPException(status_code=404, detail="Doctor not found")
        
        update_data = {
            'approved': approval.approved,
            'updatedAt': firestore.SERVER_TIMESTAMP
        }
        
        if not approval.approved and approval.rejection_reason:
            update_data['rejectionReason'] = approval.rejection_reason
        
        doctor_ref.update(update_data)
        
        return {
            "success": True,
            "message": f"Doctor {'approved' if approval.approved else 'rejected'} successfully"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/doctors")
async def get_all_doctors():
    """Get all approved doctors"""
    try:
        doctors_ref = db.collection('users').where('role', '==', 'doctor').where('approved', '==', True)
        doctors = []
        
        for doc in doctors_ref.stream():
            doctor_data = doc.to_dict()
            doctor_data['id'] = doc.id
            doctors.append(doctor_data)
        
        return {"success": True, "data": doctors, "count": len(doctors)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# =================== Hospital Management ===================

@app.get("/api/hospitals")
async def get_hospitals():
    """Get all hospitals"""
    try:
        hospitals_ref = db.collection('hospitals')
        hospitals = []
        
        for doc in hospitals_ref.stream():
            hospital_data = doc.to_dict()
            hospital_data['id'] = doc.id
            hospitals.append(hospital_data)
        
        return {"success": True, "data": hospitals, "count": len(hospitals)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/hospitals")
async def create_hospital(hospital: Hospital):
    """Create a new hospital"""
    try:
        hospital_data = hospital.dict()
        hospital_data['createdAt'] = firestore.SERVER_TIMESTAMP
        
        doc_ref = db.collection('hospitals').document()
        doc_ref.set(hospital_data)
        
        return {
            "success": True,
            "message": "Hospital created successfully",
            "hospital_id": doc_ref.id
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.put("/api/hospitals/{hospital_id}")
async def update_hospital(hospital_id: str, hospital: Hospital):
    """Update a hospital"""
    try:
        hospital_ref = db.collection('hospitals').document(hospital_id)
        
        if not hospital_ref.get().exists:
            raise HTTPException(status_code=404, detail="Hospital not found")
        
        hospital_data = hospital.dict()
        hospital_data['updatedAt'] = firestore.SERVER_TIMESTAMP
        
        hospital_ref.update(hospital_data)
        
        return {"success": True, "message": "Hospital updated successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/api/hospitals/{hospital_id}")
async def delete_hospital(hospital_id: str):
    """Delete a hospital"""
    try:
        hospital_ref = db.collection('hospitals').document(hospital_id)
        
        if not hospital_ref.get().exists:
            raise HTTPException(status_code=404, detail="Hospital not found")
        
        hospital_ref.delete()
        
        return {"success": True, "message": "Hospital deleted successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# =================== Analytics ===================

@app.get("/api/analytics")
async def get_analytics():
    """Get system analytics"""
    try:
        # Count total appointments
        appointments = db.collection('appointments').stream()
        total_appointments = sum(1 for _ in appointments)
        
        # Count total doctors
        doctors = db.collection('users').where('role', '==', 'doctor').where('approved', '==', True).stream()
        total_doctors = sum(1 for _ in doctors)
        
        # Count total patients
        patients = db.collection('users').where('role', '==', 'patient').stream()
        total_patients = sum(1 for _ in patients)
        
        # Count ambulance requests
        ambulances = db.collection('ambulance_requests').stream()
        total_ambulance_requests = sum(1 for _ in ambulances)
        
        return {
            "success": True,
            "data": {
                "total_appointments": total_appointments,
                "total_doctors": total_doctors,
                "total_patients": total_patients,
                "total_ambulance_requests": total_ambulance_requests,
                "generated_at": datetime.now().isoformat()
            }
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/analytics/appointments")
async def get_appointment_analytics():
    """Get detailed appointment analytics"""
    try:
        appointments_ref = db.collection('appointments')
        appointments = list(appointments_ref.stream())
        
        # Count by status
        status_count = {}
        for app in appointments:
            data = app.to_dict()
            status = data.get('status', 'unknown')
            status_count[status] = status_count.get(status, 0) + 1
        
        return {
            "success": True,
            "data": {
                "total": len(appointments),
                "by_status": status_count,
                "generated_at": datetime.now().isoformat()
            }
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# =================== Run Server ===================

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)
