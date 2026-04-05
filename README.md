# Road Accident Data Management System

A comprehensive Flask-based web application for managing road accident data with OLTP (Online Transaction Processing) data entry capabilities and a BI (Business Intelligence) dashboard for analysis.

## Features

### 🔐 Role-Based Access Control (RBAC)
- **Admin Users**: Full access to data entry and system management
- **Viewer Users**: Read-only access to dashboard and reports

### 📊 Data Entry (Admin Only)
- Multi-record accident data submission
- Comprehensive data validation (phone numbers, names, coordinates, etc.)
- Transactional data integrity with rollback on errors
- Support for driver, vehicle, location, weather, hospital, and officer report data

### 📈 Interactive BI Dashboard (All Users)
- Accident statistics visualization
- Filtering by year, month, state, vehicle type, and weather conditions
- Real-time data from the data warehouse

### 🛡️ Security Features
- Session-based authentication
- Input validation and sanitization
- Secure logout functionality

## Technology Stack

- **Backend**: Python Flask
- **Database**: MySQL (OLTP for data entry, Data Warehouse for reporting)
- **Frontend**: HTML templates with Bootstrap (assumed from templates)
- **Authentication**: In-memory user store with role-based permissions

## Project Structure

```
├── app.py                 # Main Flask application
├── database.sql           # Database schema and initial data
├── requirements.txt       # Python dependencies
├── templates/
│   ├── index.html         # Admin data entry form
│   ├── dashboard.html     # BI dashboard view
│   └── login.html         # User authentication
├── QUICKSTART.md          # Quick setup guide
└── README.md              # This file
```

## Database Schema

The system uses two databases:
- **road_accident_oltp**: Operational database for data entry
- **road_accident_dw**: Data warehouse for reporting and analytics

Tables include: Driver, Vehicle, Location, Weather, Hospital, Accident, Officer_Report, and corresponding dimension/fact tables in the warehouse.

## Default Users

- **Admin**: charan / charan123
- **Viewer**: sameer / sameer123
- **Viewer**: varsha / varsha143
- **Admin**: abhinav / abhinav123

## Installation & Setup

See [QUICKSTART.md](QUICKSTART.md) for detailed installation and setup instructions.

## Usage

1. Start the application: `python app.py`
2. Navigate to `http://127.0.0.1:5000/`
3. Log in with appropriate credentials
4. Admins: Use the data entry form to submit accident records
5. All users: View the dashboard for accident analytics

## API Endpoints

- `GET/POST /login`: User authentication
- `GET /logout`: User logout
- `GET /`: Admin data entry form (admin only)
- `POST /submit_data`: Submit accident data (admin only)
- `GET /dashboard`: BI dashboard (all authenticated users)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues or questions, please create an issue in the repository or contact the development team.