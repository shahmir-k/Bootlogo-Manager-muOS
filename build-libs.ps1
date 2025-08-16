#!/usr/bin/env pwsh

param(
    [switch]$Rebuild
)


# Build Libraries for Bootlogo Manager ARM64
# This script builds LÖVE, LFS, lua-zip, and all dependencies for ARM64 architecture

Write-Host 'Building ARM64 libraries for Bootlogo Manager...' -ForegroundColor Green

# Create a Dockerfile for building all required libraries
$dockerfile = @"
FROM --platform=linux/arm64 ubuntu:24.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies with caching
RUN apt-get update -y && apt-get install -y -V \
    build-essential \
    git \
    cmake \
    pkg-config \
    lua5.1-dev \
    lua5.1 \
    luajit \
    libluajit-5.1-dev \
    libzip-dev \
    libzip4 \
    libpng-dev \
    libpng16-16 \
    libfreetype6-dev \
    libopenal-dev \
    libvorbis-dev \
    libtheora-dev \
    libmodplug-dev \
    libmpg123-dev \
    libphysfs-dev \
    libsdl2-dev \
    libsdl2-image-dev \
    libsdl2-mixer-dev \
    libsdl2-ttf-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* /var/tmp/*

# Set up working directory
WORKDIR /workspace

# Clone LFS source from official repository
RUN git clone --depth 1 https://github.com/keplerproject/luafilesystem.git lfs-source

# Clone lua-zip source from official repository
RUN git clone --depth 1 https://github.com/brimworks/lua-zip.git lua-zip-source

# Clone LÖVE source from official repository (version 11.5)
RUN git clone --depth 1 --branch 11.5 https://github.com/love2d/love.git love-source

# Build LFS for ARM64 with Lua 5.1 compatibility
RUN cd lfs-source && \
    make LUA_INC=/usr/include/lua5.1 LUA_LIB=/usr/lib/aarch64-linux-gnu LUA_VERSION=5.1 CPPFLAGS="-I/usr/include/lua5.1" LDFLAGS="-L/usr/lib/aarch64-linux-gnu" && \
    make install LUA_INC=/usr/include/lua5.1 LUA_LIB=/usr/lib/aarch64-linux-gnu LUA_VERSION=5.1

# Build lua-zip for ARM64 with LuaJIT compatibility
RUN cd lua-zip-source && \
    mkdir -p build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release -DLUA_INCLUDE_DIR=/usr/include/luajit-2.1 -DLUA_LIBRARIES=/usr/lib/aarch64-linux-gnu/libluajit-5.1.so.2 -Wno-dev && \
    make -j4

# Build LÖVE for ARM64 with aggressive optimization
RUN cd love-source && \
    ./platform/unix/automagic && \
    CFLAGS="-O1 -ffast-math -fomit-frame-pointer" \
    CXXFLAGS="-O1 -ffast-math -fomit-frame-pointer" \
    LDFLAGS="-Wl,-O1 -Wl,--as-needed -Wl,--strip-all" \
    ./configure --prefix=/usr/local --with-lua=luajit --disable-audio --disable-physics --disable-video --disable-joystick --disable-touch --disable-sensor --disable-freetype --disable-ttf && \
    make -j8 && \
    make install && \
    strip /usr/local/bin/love

# Create output directories
RUN mkdir -p /workspace/arm64-libs/lib /workspace/arm64-libs/include /workspace/arm64-libs/bin

# Copy the compiled LFS library
RUN cp /usr/local/lib/lua/5.1/lfs.so /workspace/arm64-libs/lib/ && \
    echo "✓ LFS library copied"

# Copy the compiled lua-zip library
RUN mkdir -p /workspace/arm64-libs/lib/brimworks && \
    cp /workspace/lua-zip-source/build/brimworks/zip.so /workspace/arm64-libs/lib/brimworks/ && \
    echo "✓ lua-zip library copied"

# Copy libzip shared library dependencies
RUN cp /usr/lib/aarch64-linux-gnu/libzip.so.4 /workspace/arm64-libs/lib/ && \
    cp /usr/lib/aarch64-linux-gnu/libzip.so /workspace/arm64-libs/lib/ && \
    echo "✓ libzip libraries copied"

# Copy LuaJIT libraries
RUN cp /usr/lib/aarch64-linux-gnu/libluajit-5.1.so.2 /workspace/arm64-libs/lib/ && \
    cp /usr/lib/aarch64-linux-gnu/libluajit-5.1.so /workspace/arm64-libs/lib/ && \
    echo "✓ LuaJIT libraries copied"

# Copy PNG libraries
RUN cp /usr/lib/aarch64-linux-gnu/libpng16.so.16 /workspace/arm64-libs/lib/ && \
    cp /usr/lib/aarch64-linux-gnu/libpng16.so /workspace/arm64-libs/lib/ && \
    echo "✓ PNG libraries copied"

# Copy LÖVE executable and libraries
RUN cp /usr/local/bin/love /workspace/arm64-libs/bin/ && \
    cp /usr/local/lib/liblove-11.5.so /workspace/arm64-libs/lib/ && \
    ls -la /workspace/arm64-libs/lib/liblove* && \
    echo "✓ LÖVE executable and library copied"

# Copy everything from /usr/local and /usr/lib to CompleteFiles
# RUN mkdir -p /workspace/CompleteFiles/usr/local /workspace/CompleteFiles/usr/lib && \
#     cp -rL /usr/local/* /workspace/CompleteFiles/usr/local/ 2>/dev/null || true && \
#     cp -rL /usr/lib/* /workspace/CompleteFiles/usr/lib/ 2>/dev/null || true && \
#     echo "✓ Complete /usr/local and /usr/lib copied to CompleteFiles"

# Copy additional LÖVE dependencies
RUN cp /usr/lib/aarch64-linux-gnu/libfreetype.so* /workspace/arm64-libs/lib/ 2>/dev/null || true && \
    cp /usr/lib/aarch64-linux-gnu/libopenal.so* /workspace/arm64-libs/lib/ 2>/dev/null || true && \
    cp /usr/lib/aarch64-linux-gnu/libvorbis.so* /workspace/arm64-libs/lib/ 2>/dev/null || true && \
    cp /usr/lib/aarch64-linux-gnu/libmodplug.so* /workspace/arm64-libs/lib/ 2>/dev/null || true && \
    cp /usr/lib/aarch64-linux-gnu/libmpg123.so* /workspace/arm64-libs/lib/ 2>/dev/null || true && \
    cp /usr/lib/aarch64-linux-gnu/libphysfs.so* /workspace/arm64-libs/lib/ 2>/dev/null || true && \
    cp /usr/lib/aarch64-linux-gnu/libSDL2.so* /workspace/arm64-libs/lib/ 2>/dev/null || true && \
    cp /usr/lib/aarch64-linux-gnu/libSDL2_image.so* /workspace/arm64-libs/lib/ 2>/dev/null || true && \
    cp /usr/lib/aarch64-linux-gnu/libSDL2_mixer.so* /workspace/arm64-libs/lib/ 2>/dev/null || true && \
    cp /usr/lib/aarch64-linux-gnu/libSDL2_ttf.so* /workspace/arm64-libs/lib/ 2>/dev/null || true && \
    echo "✓ Additional LÖVE dependencies copied"

# Create a verification script
RUN echo '#!/bin/bash' > /workspace/verify-build.sh && \
    echo 'echo "=== ARM64 Library Build Verification ==="' >> /workspace/verify-build.sh && \
    echo 'echo "Required files:"' >> /workspace/verify-build.sh && \
    echo 'ls -la /workspace/arm64-libs/lib/libluajit-5.1.so.2' >> /workspace/verify-build.sh && \
    echo 'ls -la /workspace/arm64-libs/bin/love' >> /workspace/verify-build.sh && \
    echo 'ls -la /workspace/arm64-libs/lib/liblove-11.5.so*' >> /workspace/verify-build.sh && \
    echo 'ls -la /workspace/arm64-libs/lib/libpng16.so.16' >> /workspace/verify-build.sh && \
    echo 'ls -la /workspace/arm64-libs/lib/lfs.so' >> /workspace/verify-build.sh && \
    echo 'ls -la /workspace/arm64-libs/lib/brimworks/zip.so' >> /workspace/verify-build.sh && \
    echo 'ls -la /workspace/arm64-libs/lib/libzip.so*' >> /workspace/verify-build.sh && \
    echo 'echo "=== Build Complete ==="' >> /workspace/verify-build.sh && \
    chmod +x /workspace/verify-build.sh

# Set the default command
CMD ["/workspace/verify-build.sh"]
"@

$dockerfile | Out-File -FilePath "Dockerfile.arm64-build" -Encoding ASCII

# Check if Docker image already exists to avoid rebuilding
$imageExists = docker images -q bootlogo-manager-arm64-builder
if ($imageExists) {
    if ($Rebuild) {
        Write-Host 'Docker image already exists, force rebuilding...' -ForegroundColor Yellow
        docker build --platform linux/arm64 -f Dockerfile.arm64-build -t bootlogo-manager-arm64-builder --no-cache --progress=plain .
    }
    else {
        Write-Host 'Docker image already exists, using cached image...' -ForegroundColor Green
        Write-Host 'To force rebuild, use the -Rebuild switch' -ForegroundColor Yellow
        docker build --platform linux/arm64 -f Dockerfile.arm64-build -t bootlogo-manager-arm64-builder --progress=plain .
    }
}
else {
    Write-Host 'Building Docker image for ARM64 library compilation...' -ForegroundColor Cyan
    docker build --platform linux/arm64 -f Dockerfile.arm64-build -t bootlogo-manager-arm64-builder --progress=plain .
}

Write-Host 'Extracting built libraries from Docker container...' -ForegroundColor Cyan

# Create a temporary container and copy files from it
$containerId = docker create --platform linux/arm64 bootlogo-manager-arm64-builder
docker cp "${containerId}:/workspace/arm64-libs" .
# Write-Host 'Copying CompleteFiles from container...' -ForegroundColor Cyan
# docker cp "${containerId}:/workspace/CompleteFiles" . 2>$null
# if ($LASTEXITCODE -ne 0) {
#     Write-Host '[WARNING] Failed to copy CompleteFiles, trying alternative method...' -ForegroundColor Yellow
#     # Try copying individual directories
#     docker cp "${containerId}:/workspace/CompleteFiles/usr/local" ./CompleteFiles/usr/ 2>$null
#     docker cp "${containerId}:/workspace/CompleteFiles/usr/lib" ./CompleteFiles/usr/ 2>$null
# }
docker rm $containerId

Write-Host 'ARM64 library build complete!' -ForegroundColor Green
Write-Host 'Libraries are now in the arm64-libs directory' -ForegroundColor White
#Write-Host 'Complete files are now in the CompleteFiles directory' -ForegroundColor White

# Create required directory structure
Write-Host 'Creating directory structure...' -ForegroundColor Cyan
$directories = @(
    '.bootlogo/bin',
    '.bootlogo/bin/libs.aarch64',
    '.bootlogo/bin/libs.aarch64/brimworks'
)

foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "Created directory: $dir" -ForegroundColor Gray
    }
}

# Define the required files and their source/destination paths
$requiredFiles = @(
    @{ Source = 'arm64-libs/lib/libluajit-5.1.so.2'; Destination = '.bootlogo/bin/libs.aarch64/libluajit-5.1.so.2'; Description = 'LuaJIT library' },
    @{ Source = 'arm64-libs/bin/love'; Destination = '.bootlogo/bin/love'; Description = 'LOVE executable' },
    @{ Source = 'arm64-libs/lib/liblove-11.5.so'; Destination = '.bootlogo/bin/libs.aarch64/liblove-11.5.so'; Description = 'LOVE library' },
    @{ Source = 'arm64-libs/lib/libpng16.so.16'; Destination = '.bootlogo/bin/libs.aarch64/libpng16.so.16'; Description = 'PNG library' },
    @{ Source = 'arm64-libs/lib/lfs.so'; Destination = '.bootlogo/bin/libs.aarch64/lfs.so'; Description = 'LFS library' },
    @{ Source = 'arm64-libs/lib/brimworks/zip.so'; Destination = '.bootlogo/bin/libs.aarch64/brimworks/zip.so'; Description = 'lua-zip library' },
    #@{ Source = 'arm64-libs/lib/libzip.so'; Destination = '.bootlogo/bin/libs.aarch64/libzip.so'; Description = 'libzip library' },
    @{ Source = 'arm64-libs/lib/libzip.so.4'; Destination = '.bootlogo/bin/libs.aarch64/libzip.so.4'; Description = 'libzip library (version 4)' }
)

# Copy all required files
Write-Host 'Copying required files...' -ForegroundColor Cyan
$successCount = 0
$totalCount = $requiredFiles.Count

foreach ($file in $requiredFiles) {
    if (Test-Path $file.Source) {
        Copy-Item $file.Source $file.Destination -Force
        Write-Host '[OK] Copied ' -NoNewline -ForegroundColor Green; Write-Host "$($file.Description): $($file.Destination)" -ForegroundColor White
        $successCount++
    }
    else {
        Write-Host '[ERROR] Missing ' -NoNewline -ForegroundColor Red; Write-Host "$($file.Description): $($file.Source)" -ForegroundColor White
    }
}

# Copy additional LÖVE libraries if they exist
$additionalLibraries = @(
    #'liblove-11.5.so.0',
    #'libluajit-5.1.so',
    #'libpng16.so'
)

foreach ($lib in $additionalLibraries) {
    $sourcePath = "arm64-libs/lib/$lib"
    if (Test-Path $sourcePath) {
        Copy-Item $sourcePath ".bootlogo/bin/libs.aarch64/" -Force
        Write-Host '[OK] Copied additional library: ' -NoNewline -ForegroundColor Green; Write-Host "$lib" -ForegroundColor White
    }
}

# Copy LÖVE share files if they exist
# if (Test-Path 'arm64-libs/share/love') {
#     Copy-Item 'arm64-libs/share/love' '.bootlogo/bin/' -Recurse -Force
#     Write-Host '[OK] Copied LÖVE share files' -ForegroundColor Green
# }

# Clean up temporary files
Write-Host 'Cleaning up temporary files...' -ForegroundColor Cyan
Remove-Item 'Dockerfile.arm64-build' -Force -ErrorAction SilentlyContinue
if (Test-Path 'arm64-libs') {
    Remove-Item 'arm64-libs' -Recurse -Force
    Write-Host 'Cleaned up temporary build files' -ForegroundColor Yellow
}
# Keep CompleteFiles for analysis
#Write-Host 'CompleteFiles directory preserved for analysis' -ForegroundColor Green

# Final verification
Write-Host "`n=== Build Summary ===" -ForegroundColor Yellow
Write-Host "Successfully copied: $successCount/$totalCount required files" -ForegroundColor $(if ($successCount -eq $totalCount) { 'Green' } else { 'Red' })

# List all generated files
Write-Host "`nGenerated files:" -ForegroundColor Cyan
$generatedFiles = @(
    '.bootlogo/bin/libs.aarch64/libluajit-5.1.so.2',
    '.bootlogo/bin/love',
    '.bootlogo/bin/libs.aarch64/liblove-11.5.so',
    '.bootlogo/bin/libs.aarch64/libpng16.so.16',
    '.bootlogo/bin/libs.aarch64/lfs.so',
    '.bootlogo/bin/libs.aarch64/brimworks/zip.so',
    #'.bootlogo/bin/libs.aarch64/libzip.so',
    '.bootlogo/bin/libs.aarch64/libzip.so.4'
)

foreach ($file in $generatedFiles) {
    if (Test-Path $file) {
        $size = (Get-Item $file).Length
        $sizeKB = [math]::Round($size / 1KB, 1)
        Write-Host '[OK] ' -NoNewline -ForegroundColor Green; Write-Host "$file ($sizeKB KB)" -ForegroundColor White
    }
    else {
        Write-Host "[MISSING] $file (MISSING)" -ForegroundColor Red
    }
}

Write-Host "`n=== Build Complete ===" -ForegroundColor Green
Write-Host "All ARM64 libraries have been built and organized for Bootlogo Manager" -ForegroundColor White
Write-Host "The application is now ready for packaging and deployment" -ForegroundColor White
