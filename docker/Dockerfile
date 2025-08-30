# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy csproj files and restore dependencies
COPY ["src/__ApplicationName__.Api/__ApplicationName__.Api.csproj", "src/__ApplicationName__.Api/"]
COPY ["src/__ApplicationName__.Shared/__ApplicationName__.Shared.csproj", "src/__ApplicationName__.Shared/"]

# Copy module projects if they exist
COPY ["src/Modules/Orders/Orders.Api/Orders.Api.csproj", "src/Modules/Orders/Orders.Api/"] 2>/dev/null || true
COPY ["src/Modules/Orders/Orders.Application/Orders.Application.csproj", "src/Modules/Orders/Orders.Application/"] 2>/dev/null || true
COPY ["src/Modules/Orders/Orders.Domain/Orders.Domain.csproj", "src/Modules/Orders/Orders.Domain/"] 2>/dev/null || true
COPY ["src/Modules/Orders/Orders.Infrastructure/Orders.Infrastructure.csproj", "src/Modules/Orders/Orders.Infrastructure/"] 2>/dev/null || true

# Copy solution file
COPY ["__ApplicationName__.sln", "./"]

# Restore dependencies
RUN dotnet restore "__ApplicationName__.sln"

# Copy everything else
COPY . .

# Build the application
WORKDIR "/src/src/__ApplicationName__.Api"
RUN dotnet build "__ApplicationName__.Api.csproj" -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish "__ApplicationName__.Api.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app

# Create non-root user
RUN adduser --disabled-password --gecos '' appuser && chown -R appuser /app
USER appuser

# Copy published app
COPY --from=publish /app/publish .

# Create logs directory
USER root
RUN mkdir -p /app/logs && chown -R appuser:appuser /app/logs
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Expose ports
EXPOSE 8080
EXPOSE 8081

ENTRYPOINT ["dotnet", "__ApplicationName__.Api.dll"]
