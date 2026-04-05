from flask import Flask, render_template, request, flash, redirect, url_for, session
import mysql.connector
import re
from functools import wraps

app = Flask(__name__)
app.secret_key = "safety_drive_final_master_2026"

# --- MySQL Credentials ---
db_config = {
    'host': '127.0.0.1',
    'user': 'root',
    'password': 'Kclr0206#@',
    'database': 'road_accident_oltp'
}

# --- Mock User Database for RBAC ---
USERS = {
    "charan": {"password": "charan123", "role": "admin"},
    "sameer": {"password": "sameer123", "role": "viewer"},
    "varsha": {"password": "varsha143", "role": "viewer"},
    "abhinav": {"password": "abhinav123", "role": "admin"}
}

# --- Authentication Decorators ---
def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'username' not in session:
            flash("🔒 Please log in to access the system.", "warning")
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function

def admin_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'username' not in session:
            return redirect(url_for('login'))
        if session.get('role') != 'admin':
            flash("⛔ Access Denied: You do not have permission to enter or edit data. You are in View-Only mode.", "danger")
            return redirect(url_for('dashboard'))
        return f(*args, **kwargs)
    return decorated_function

# ==========================================
# ROUTE 0: LOGIN & LOGOUT
# ==========================================
@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        
        user = USERS.get(username)
        if user and user['password'] == password:
            session['username'] = username
            session['role'] = user['role']
            flash(f"✅ Welcome back, {username.capitalize()}!", "success")
            
            # Direct users based on their role
            if user['role'] == 'admin':
                return redirect(url_for('index'))
            else:
                return redirect(url_for('dashboard'))
        else:
            flash("❌ Invalid credentials. Please try again.", "danger")
            
    return render_template('login.html')

@app.route('/logout')
def logout():
    session.clear()
    flash("👋 You have been securely logged out.", "success")
    return redirect(url_for('login'))

# ==========================================
# ROUTE 1: OLTP DATA ENTRY (Admin Only)
# ==========================================
@app.route('/')
@admin_required
def index():
    return render_template('index.html')

@app.route('/submit_data', methods=['POST'])
@admin_required
def submit_data():
    conn = mysql.connector.connect(**db_config)
    conn.autocommit = False  
    cursor = conn.cursor()

    try:
        # Fetch ALL arrays from the form
        drivers = request.form.getlist('driver_name[]')
        licenses = request.form.getlist('license_number[]')
        phones = request.form.getlist('phone[]')
        addresses = request.form.getlist('address[]')
        plates = request.form.getlist('vehicle_number[]')
        v_types = request.form.getlist('vehicle_type[]')
        models = request.form.getlist('model[]')
        states = request.form.getlist('state[]')
        cities = request.form.getlist('city[]')
        areas = request.form.getlist('area[]')
        lats = request.form.getlist('latitude[]')
        longs = request.form.getlist('longitude[]')
        weathers = request.form.getlist('weather_condition[]')
        temps = request.form.getlist('temperature[]')
        humidities = request.form.getlist('humidity[]')
        hospitals = request.form.getlist('hospital_name[]')
        h_cities = request.form.getlist('hospital_city[]')
        h_addresses = request.form.getlist('hospital_address[]')
        dates = request.form.getlist('accident_date[]')
        times = request.form.getlist('accident_time[]')
        casualties_list = request.form.getlist('casualties[]')
        statuses = request.form.getlist('accident_status[]')
        officers = request.form.getlist('officer_name[]')
        r_dates = request.form.getlist('report_date[]')
        details = request.form.getlist('report_details[]')

        for i in range(len(drivers)):
            p = phones[i].strip()
            if not (p.isdigit() and len(p) == 10): raise ValueError(f"Row {i+1}: Phone must be exactly 10 digits.")
            if not re.match(r"^[A-Za-z\s\.\-]+$", drivers[i]) or not re.match(r"^[A-Za-z\s\.\-]+$", officers[i]): raise ValueError(f"Row {i+1}: Names can only contain letters, spaces, dots, and hyphens.")

            try:
                val_cas = int(casualties_list[i])
                val_temp = int(temps[i])
                val_hum = int(humidities[i])
                val_lat = float(lats[i])
                val_lon = float(longs[i])
                if val_cas < 0: raise ValueError(f"Row {i+1}: Casualties cannot be negative.")
            except ValueError:
                raise ValueError(f"Row {i+1}: Casualties, Temp, Humidity, and Coordinates must be valid numbers.")

            allowed_weather = ['Clear', 'Rainy', 'Foggy', 'Overcast']
            allowed_status = ['Active', 'Under Investigation', 'Closed']
            allowed_vtype = ['Bike', 'Car', 'SUV', 'Bus', 'Truck', 'Other']
            
            if weathers[i] not in allowed_weather: raise ValueError(f"Row {i+1}: Invalid Weather Option.")
            if statuses[i] not in allowed_status: raise ValueError(f"Row {i+1}: Invalid Accident Status.")
            if v_types[i] not in allowed_vtype: raise ValueError(f"Row {i+1}: Invalid Vehicle Type.")

            cursor.execute("INSERT INTO Driver (driver_name, license_number, phone, address) VALUES (%s,%s,%s,%s)", (drivers[i].upper(), licenses[i].upper(), p, addresses[i]))
            d_id = cursor.lastrowid

            cursor.execute("INSERT INTO Vehicle (driver_id, vehicle_number, vehicle_type, model) VALUES (%s,%s,%s,%s)", (d_id, plates[i].upper(), v_types[i], models[i]))
            v_id = cursor.lastrowid

            cursor.execute("INSERT INTO Location (state, city, area, latitude, longitude) VALUES (%s,%s,%s,%s,%s)", (states[i], cities[i], areas[i], val_lat, val_lon))
            l_id = cursor.lastrowid

            cursor.execute("INSERT INTO Weather (weather_condition, temperature, humidity) VALUES (%s,%s,%s)", (weathers[i], val_temp, val_hum))
            w_id = cursor.lastrowid

            cursor.execute("INSERT INTO Hospital (hospital_name, hospital_address, city) VALUES (%s,%s,%s)", (hospitals[i], h_addresses[i], h_cities[i]))
            h_id = cursor.lastrowid

            cursor.execute("""INSERT INTO Accident (vehicle_id, location_id, weather_id, hospital_id, accident_date, accident_time, casualties, accident_status) 
                              VALUES (%s,%s,%s,%s,%s,%s,%s,%s)""", (v_id, l_id, w_id, h_id, dates[i], times[i], val_cas, statuses[i]))
            a_id = cursor.lastrowid

            cursor.execute("INSERT INTO Officer_Report (accident_id, officer_name, report_details, report_date) VALUES (%s,%s,%s,%s)", (a_id, officers[i].upper(), details[i], r_dates[i]))

        conn.commit()
        flash(f"🔥 SUCCESS: {len(drivers)} Record(s) Locked & Synced to Data Warehouse!", "success")

    except Exception as e:
        conn.rollback() 
        flash(f"❌ DATA REJECTED: {str(e)}", "danger")
    finally:
        cursor.close()
        conn.close()

    return redirect(url_for('index'))

# ==========================================
# ROUTE 2: INTERACTIVE BI DASHBOARD (All Users)
# ==========================================
@app.route('/dashboard')
@login_required
def dashboard():
    conn = mysql.connector.connect(**db_config)
    cursor = conn.cursor(dictionary=True)

    try:
        cursor.execute("""
            SELECT 
                f.fact_id, f.casualties,
                t.year, LPAD(t.month, 2, '0') as month,
                l.state, l.city,
                v.vehicle_type,
                w.weather_condition
            FROM road_accident_dw.Fact_Accident f
            JOIN road_accident_dw.Dim_Time t ON f.time_id = t.time_id
            JOIN road_accident_dw.Dim_Location l ON f.location_id = l.location_id
            JOIN road_accident_dw.Dim_Vehicle v ON f.vehicle_id = v.vehicle_id
            JOIN road_accident_dw.Dim_Weather w ON f.weather_id = w.weather_id
        """)
        raw_data = cursor.fetchall()

        clean_data = []
        for row in raw_data:
            clean_data.append({
                'fact_id': int(row['fact_id']),
                'casualties': int(row['casualties'] or 0),
                'year': str(row['year']),
                'month': str(row['month']),
                'state': str(row['state']),
                'vehicle_type': str(row['vehicle_type']),
                'weather_condition': str(row['weather_condition'])
            })

        return render_template('dashboard.html', dataset=clean_data)

    except Exception as e:
        return f"<h1>Data Warehouse Connection Error</h1><p>{e}</p>"
    finally:
        cursor.close()
        conn.close()

if __name__ == '__main__':
    app.run(debug=True)