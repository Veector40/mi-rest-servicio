# Use an official Python base image
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /app

# Copy the current directory contents into the container
COPY . /app

RUN pip install flask

EXPOSE 80

# Run app.py when the container launches
CMD ["python", "app.py"]
