# Use node version 10 image
FROM node:10

# Create app directory
WORKDIR /usr/src/app

# Download code from GIT
RUN wget https://github.com/rearc/quest/archive/refs/heads/master.zip

# Extract app from ZIP
RUN unzip master.zip

# Remove ZIP file
RUN rm master.zip

# Move files to parent WORKDIR
RUN mv quest-master/* ./

# Remove temp directory
RUN rm -Rf quest-master

# Install node application dependencies
RUN npm install

# Specify port for application
EXPOSE 3000

# Define SECRET_WORD Environment Variable
ENV SECRET_WORD=TwelveFactor

# Execute the application 
CMD ["npm", "start"]