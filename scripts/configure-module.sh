#!/bin/bash

# Script para configurar un módulo en Program.cs
# Uso: ./configure-module.sh ModuleName RootNamespace ApplicationName

if [ $# -lt 3 ]; then
    echo "Error: se requieren 3 parámetros"
    echo "Uso: $0 ModuleName RootNamespace ApplicationName"
    exit 1
fi

MODULE_NAME=$1
ROOT_NAMESPACE=$2
APPLICATION_NAME=$3

# Verificar que estamos en el directorio correcto
if [ ! -d "src" ]; then
    echo "Error: este script debe ejecutarse desde la raíz del proyecto (donde está la carpeta src)"
    exit 1
fi

PROGRAM_PATH="src/$APPLICATION_NAME.Api/Program.cs"

if [ ! -f "$PROGRAM_PATH" ]; then
    echo "Error: no se encontró el archivo Program.cs en $PROGRAM_PATH"
    exit 1
fi

printf "\033[32mConfigurando módulo '%s' en Program.cs...\033[0m\n" "$MODULE_NAME"

# Crear respaldo
cp "$PROGRAM_PATH" "$PROGRAM_PATH.backup"

# Normalizar usings (solo Api.Extensions y Module Api.Extensions)
MODULE_EXT_USING="using $ROOT_NAMESPACE.Modules.$MODULE_NAME.Api.Extensions;"
API_EXT_USING="using $ROOT_NAMESPACE.Api.Extensions;"

for USING in "$MODULE_EXT_USING" "$API_EXT_USING"; do
    if ! grep -qF "$USING" "$PROGRAM_PATH"; then
        awk -v ue="$USING" '
            NR==1{print}
            NR>1 && !p && $0 ~ /^using / {print ue; p=1}
            {print}
        ' "$PROGRAM_PATH" > "$PROGRAM_PATH.tmp" && mv "$PROGRAM_PATH.tmp" "$PROGRAM_PATH"
        printf "\033[32m✅ Agregado %s\033[0m\n" "$USING"
    fi
done

# Asegurar que exista 'var app = builder.Build();'
APP_BUILD_LINE='var app = builder.Build();'
if ! grep -q "var[[:space:]]\+app[[:space:]]*=[[:space:]]*builder.Build()" "$PROGRAM_PATH"; then
    awk -v abl="$APP_BUILD_LINE" '
        BEGIN{ins=0}
        ins==0 && ($0 ~ /if \(app\.Environment\.IsDevelopment\(\)\)|app\.UseSerilogRequestLogging\(\);|app\.Use|app\.Map|try \{|app\.Run\(\);/) {
            print abl; print ""; ins=1
        }
        {print}
    ' "$PROGRAM_PATH" > "$PROGRAM_PATH.tmp" && mv "$PROGRAM_PATH.tmp" "$PROGRAM_PATH"
    printf "\033[32m✅ Insertado 'var app = builder.Build();'\033[0m\n"
fi

# Agregar configuración de servicios
SERVICE_CONFIG="builder.Services.Add${MODULE_NAME}Module(builder.Configuration);"
if ! grep -qF "$SERVICE_CONFIG" "$PROGRAM_PATH"; then
    awk -v sc="$SERVICE_CONFIG" '
        BEGIN{done=0}
        /\/\/ Módulos/ && !done {print sc; done=1}
        {print}
    ' "$PROGRAM_PATH" > "$PROGRAM_PATH.tmp" && mv "$PROGRAM_PATH.tmp" "$PROGRAM_PATH"
    printf "\033[32m✅ Agregada configuración de servicios para %s\033[0m\n" "$MODULE_NAME"
fi

# Asegurar que exista 'app.MapControllers();'
if ! grep -q "app.MapControllers();" "$PROGRAM_PATH"; then
    awk '
        BEGIN{done=0}
        /app\.Use[[:alnum:]]+Module\(\);/ && !done {print "app.MapControllers();"; print ""; done=1}
        {print}
    ' "$PROGRAM_PATH" > "$PROGRAM_PATH.tmp" && mv "$PROGRAM_PATH.tmp" "$PROGRAM_PATH"
    printf "\033[32m✅ Agregado app.MapControllers()\033[0m\n"
fi

# Agregar configuración del pipeline del módulo
APP_USE_CONFIG="app.Use${MODULE_NAME}Module();"
if ! grep -qF "$APP_USE_CONFIG" "$PROGRAM_PATH"; then
    awk -v auc="$APP_USE_CONFIG" '
        /\/\/ Endpoints de módulos/ { print auc; next }
        {print}
    ' "$PROGRAM_PATH" > "$PROGRAM_PATH.tmp" && mv "$PROGRAM_PATH.tmp" "$PROGRAM_PATH"
    printf "\033[32m✅ Agregado app.Use%sModule()\033[0m\n" "$MODULE_NAME"
fi

printf "\n\033[32mConfiguración completada exitosamente!\033[0m\n"
printf "\033[33mEl módulo '%s' ha sido configurado en Program.cs\033[0m\n" "$MODULE_NAME"
printf "\n\033[34mRecomendaciones:\033[0m\n"
printf "\033[37m1. Revisa el archivo Program.cs para verificar la configuración\033[0m\n"
printf "\033[37m2. Ejecuta 'dotnet build' para verificar que no hay errores\033[0m\n"
printf "\033[37m3. Ejecuta 'dotnet run --project src/%s.Api' para probar\033[0m\n" "$APPLICATION_NAME"
