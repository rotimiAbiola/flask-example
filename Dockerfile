# Use the official Python image from the Docker Hub
FROM python:3.8-slim

# Set the working directory in the container
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Install any needed packages specified in requirements.txt
RUN pip install flask

# Set environment variable for Flask to run in development mode
ENV FLASK_APP=main.py
ENV FLASK_RUN_HOST=0.0.0.0
ENV FLASK_RUN_PORT=5000

# Make port 5000 available to the world outside this container
EXPOSE 5000

# Run the flask command when the container launches
CMD ["flask", "run", "--host=0.0.0.0", "--port=5000"]
