# Build stage
FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /app

# Copy Maven files
COPY pom.xml .
COPY src ./src

# Download dependencies and build
RUN apk add --no-cache maven && \
    mvn dependency:go-offline -B && \
    mvn package -DskipTests -B

# Runtime stage
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Update Alpine packages to fix CVEs
RUN apk upgrade --no-cache

# Create uploads directory
RUN mkdir -p /app/uploads

# Copy built JAR from builder
COPY --from=builder /app/target/*.jar application.jar

# Expose port
EXPOSE 8080

# Run the application
ENTRYPOINT ["java", "-jar", "application.jar"]
