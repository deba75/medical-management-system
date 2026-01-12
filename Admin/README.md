# 🏥 TeleMedicine Admin Panel (Python FastAPI)

Backend API for administrative functions of the TeleMedicine system.

## 🚀 Quick Start

### Prerequisites
- Python 3.8+
- Firebase project with service account key

### Installation

1. **Install dependencies:**
```powershell
cd Admin
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

2. **Add Firebase credentials:**
   - Download service account key from Firebase Console
   - Save as `serviceAccountKey.json` in this directory

3. **Run the server:**
```powershell
python main.py
```

Server will start at: `http://localhost:8000`

## 📚 API Documentation

Interactive API docs available at:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## 🔌 API Endpoints

### Doctor Management
- `GET /api/doctors/pending` - Get doctors awaiting approval
- `POST /api/doctors/approve` - Approve or reject doctor
- `GET /api/doctors` - Get all approved doctors

### Hospital Management
- `GET /api/hospitals` - List all hospitals
- `POST /api/hospitals` - Create new hospital
- `PUT /api/hospitals/{id}` - Update hospital
- `DELETE /api/hospitals/{id}` - Delete hospital

### Analytics
- `GET /api/analytics` - Get system-wide analytics
- `GET /api/analytics/appointments` - Get appointment statistics

## 📝 Example Requests

### Approve a Doctor
```bash
curl -X POST http://localhost:8000/api/doctors/approve \
  -H "Content-Type: application/json" \
  -d '{
    "doctor_id": "doctor123",
    "approved": true
  }'
```

### Create a Hospital
```bash
curl -X POST http://localhost:8000/api/hospitals \
  -H "Content-Type: application/json" \
  -d '{
    "name": "City General Hospital",
    "address": "123 Main St",
    "city": "Dhaka",
    "phone": "+880-1234567890",
    "email": "info@citygeneral.com",
    "specialties": ["Cardiology", "Neurology"],
    "is_emergency_available": true
  }'
```

### Get Analytics
```bash
curl http://localhost:8000/api/analytics
```

## 🔐 Security Notes

- **Production:** Update CORS settings in `main.py` to allow only your frontend URL
- **Service Account Key:** Never commit `serviceAccountKey.json` to version control
- **Environment Variables:** Consider using `.env` file for sensitive configuration

## 🏗️ Project Structure

```
Admin/
├── main.py                  # FastAPI application
├── requirements.txt         # Python dependencies
├── serviceAccountKey.json   # Firebase credentials (gitignored)
└── README.md               # This file
```

## 📦 Dependencies

- **FastAPI** - Modern web framework
- **Uvicorn** - ASGI server
- **firebase-admin** - Firebase Admin SDK
- **Pydantic** - Data validation

## 🐛 Troubleshooting

### Port already in use
```powershell
# Kill process on port 8000
netstat -ano | findstr :8000
taskkill /PID <PID> /F
```

### Firebase credentials error
- Ensure `serviceAccountKey.json` exists
- Verify file path in `main.py`
- Check Firebase project permissions

## 🚀 Deployment

### Using Uvicorn
```powershell
uvicorn main:app --host 0.0.0.0 --port 8000
```

### Using Gunicorn (Linux/macOS)
```bash
gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker
```

## 📖 Additional Resources

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
- [Uvicorn Documentation](https://www.uvicorn.org/)

---

**Version:** 1.0.0  
**Status:** Active Development
