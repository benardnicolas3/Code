#! /bin/sh
#
# Configure le chemin de classe pour Java et démarre le client de ligne de commande de plate-forme croisée TFS.
#

# BASE_DIRECTORY est le répertoire contenant les bibliothèques Java
si [ -z  "$TF_CLC_HOME"  ] ; puis
 BASE_DIRECTORY ='dirname  "$0"' 
Autre
 BASE_DIRECTORY ="$TF_CLC_HOME» 
Fi

TOKEN_REQUIRED_JAR ="$BASE_DIRECTORY/lib/com.microsoft.tfs.core.jar» 
si [ ! ! -f  "$TOKEN_REQUIRED_JAR"  ] ; puis
    echo  "Impossible de trouver un JAR requis: $TOKEN_REQUIRED_JAR n’existe pas» 
    Sortie
Fi

# Emplacement par défaut pour la plupart des plates-formes Unix.
SETTINGS_DIRECTORY ="~/.microsoft/Team Foundation/4.0» 

# Détecter le répertoire de plate-forme, d’architecture et de paramètres.
cas  'uname -s'  dans
    CYGWIN_NT*)
 PLATE-FORME=cygne
 ARCH ='ume -m' 
 SETTINGS_DIRECTORY= "'cygpath -u $USERPROFILE'/Local Settings/Application Data/Microsoft/Team Foundation/4.0» 
        # Besoin d’échapper aux espaces incorporés dans le nom du répertoire
 SETTINGS_DIRECTORY='echo $SETTINGS_DIRECTORY | sed  "s// \ /g"' 
        ;;
    AIX)
        PLATFORM=aix
 ARCH ='uname -p' 
        ;;
    Linux)
        PLATFORM=linux
 ARCH ='ume -m' 
        ;;
    SunOS)
 PLATE-FORME=solaris
 ARCH ='uname -p' 
        ;;
    HP-UX)
        PLATFORM=hpux
 ARCH ='ume -m' 
        ;;
    Darwin)
        PLATFORM=macosx
        ARCH=""
 SETTINGS_DIRECTORY ="~/Library/Microsoft/Team Foundation/4.0/» 
        ;;
    FreeBSD)
        PLATFORM=freebsd
 ARCH ='ume -m' 
        ;;
    OS/390)
        PLATFORM=zos
        ARCH=390
        ;;
    *)
 PLATFORM=inconnu
 ARCH=inconnu
        ;;
Ald

# Mapper l’architecture d’umame en architecture OSGI.
cas $ARCH dans
    i386|i486|i586|i686)
        ARCH=x86
        
        # Solaris rapports i386 pour les versions x86 et AMD64, nous avons donc
        # pour faire plus de détection pour la taille de l’architecture.
        if [ "$PLATFORM" = "solaris" ] ; then
            if [ `isainfo -b` = "64" ] ; then
                ARCH="x86_64"
            fi
        fi
        ;;
    x86_64)
        ARCH=x86_64
        ;;
    sparc)
        ARCH=sparc
        ;;
    ppc|ppc64|powerpc)
        ARCH=ppc
        ;;
    9000/*)
        ARCH=PA_RISC
        ;;
    ia64)
        # Eclipse only supports the ia64_32 JVM.
        ARCH=ia64_32
        ;;
    390)
        ;;
    unknown)
        ;;
esac

CLC_CLASSPATH=
export CLC_CLASSPATH

# Add check-in policy implementations in the user's home directory
# first, so they can override standard CLC libraries.
if [ -d "$SETTINGS_DIRECTORY"/policies ] ; then
    for POLICY_JAR in "$SETTINGS_DIRECTORY"/policies/*.jar ; do
        # Test for the file to work around the empty wildcard expansion case.
        if [ -f "$POLICY_JAR" ] ; then
            CLC_CLASSPATH="$CLC_CLASSPATH:$POLICY_JAR"
        fi
    done
fi

# Standard CLC resources.  Site-wide check-in policies can be dropped in 
# the lib directory.
#
# 3/25/2015 Workaround added:
# Make sure that AppInsights SDK is the last in CLASS_PATH, 
# otherwise it will destroy CLC logging.
#
# Can be removed after (and if) the issue is fixed in AppInsights.

AI_JAR=
for LIBRARY_JAR in "$BASE_DIRECTORY"/lib/*.jar ; do
    if expr "$LIBRARY_JAR" : ".*/applicationinsights[^/]*" > /dev/null; then
 AI_JAR ="$LIBRARY_JAR»  
    Autre
 CLC_CLASSPATH= "$CLC_CLASSPATH:$LIBRARY_JAR» 
    Fi
Fait
CLC_CLASSPATH= "$CLC_CLASSPATH:$AI_JAR» 

# Convertir en chemin de classe de style Windows
si [  "$PLATFORM"  =  "cygwin"  ] ; puis
 CLC_CLASSPATH ='cygpath -wp  "$CLC_CLASSPATH"' 
 BASE_DIRECTORY ='cygpath -w  "$BASE_DIRECTORY"' 
Fi

# Sun JVM 1.4 sur Linux peut bloquer par manque d’entropie et de causer le
# client à accrocher si /dev/random est utilisé. /dev/urontom ne bloquera pas.
RANDOM_DEVICE_PROPERTY=""
si [  'uname'  =  "Linux"  ] ; puis
 RANDOM_DEVICE_PROPERTY ="-Djava.security.egd=file:/dev/urandom» 
Fi

exec java -Xmx2048M -classpath  "$CLC_CLASSPATH"  $TF_ADDITIONAL_JAVA_ARGS \
	"-Dcom.microsoft.tfs.jni.native.base-directory=$BASE_DIRECTORY/native" \
    $RANDOM_DEVICE_PROPERTY com.microsoft.tfs.client.clc.vc.Main "$@"