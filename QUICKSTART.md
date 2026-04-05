# Quick Start Guide

This guide will help you get the Road Accident Data Management System up and running quickly.

## Prerequisites

- Python 3.8 or higher
- MySQL Server installed and running
- Git (optional, for cloning the repository)

## Installation

1. **Clone or download the project**:
   - Download the project files to your local machine.

2. **Install Python dependencies**:
   ```
   pip install -r requirements.txt
   ```

3. **Set up the MySQL database**:
   - Open MySQL Workbench or your preferred MySQL client.
   - Run the `database.sql` script to create the necessary databases and tables.
   - Ensure the database credentials in `app.py` match your MySQL setup (default: host='127.0.0.1', user='root', password='Kclr0206#@', database='road_accident_oltp').

4. **Update database configuration** (if needed):
   - Edit the `db_config` dictionary in `app.py` to match your MySQL credentials.

## Running the Application

1. **Start the Flask application**:
   ```
   python app.py
   ```

2. **Access the application**:
   - Open your web browser and go to `http://127.0.0.1:5000/`
   - Log in with one of the predefined user accounts:
     - Admin: username `charan`, password `charan123`
     - Viewer: username `sameer`, password `sameer123` (or other viewers)

## Usage

- **Admins** can access the data entry form at the root URL and submit accident data.
- **Viewers** are redirected to the dashboard for viewing accident statistics.
- Use the logout link to securely end your session.

## Troubleshooting

- If you encounter database connection errors, verify your MySQL server is running and credentials are correct.
- Ensure all required Python packages are installed.
- Check that the database schema has been created by running `database.sql`.

For more detailed information, refer to the README.md file.