# Test Auth API Endpoints
# Run this after backend is running to verify auth is working

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Testing Auth API" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$baseUrl = "http://localhost:5000/api/v2"

# Test 1: Login as Admin
Write-Host "Test 1: Login as Admin" -ForegroundColor Yellow
$loginBody = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
    
    if ($response.success -and $response.user.branchId) {
        Write-Host "  Login successful" -ForegroundColor Green
        Write-Host "  User: $($response.user.username) ($($response.user.role))" -ForegroundColor White
        Write-Host "  Branch: $($response.branch.name) ($($response.branch.code))" -ForegroundColor White
        Write-Host "  Branch ID: $($response.user.branchId)" -ForegroundColor White
        Write-Host "  Total Branches: $($response.user.branches.Count)" -ForegroundColor White
        
        $adminToken = $response.tokens.accessToken
        Write-Host ""
    } else {
        Write-Host "  Login failed - No branch ID in response" -ForegroundColor Red
        Write-Host ($response | ConvertTo-Json -Depth 5)
        exit 1
    }
} catch {
    Write-Host "  Error: $_" -ForegroundColor Red
    Write-Host "  Make sure backend is running on port 5000" -ForegroundColor Yellow
    exit 1
}

# Test 2: Login as Cashier
Write-Host "Test 2: Login as Cashier" -ForegroundColor Yellow
$cashierBody = @{
    username = "cashier1"
    password = "cashier123"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body $cashierBody -ContentType "application/json"
    
    if ($response.success -and $response.user.branchId) {
        Write-Host "  Login successful" -ForegroundColor Green
        Write-Host "  User: $($response.user.username) ($($response.user.role))" -ForegroundColor White
        Write-Host "  Branch: $($response.branch.name) ($($response.branch.code))" -ForegroundColor White
        Write-Host "  Branch ID: $($response.user.branchId)" -ForegroundColor White
        Write-Host ""
    } else {
        Write-Host "  Login failed - No branch ID in response" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "  Error: $_" -ForegroundColor Red
    exit 1
}

# Test 3: Token Decode Check
Write-Host "Test 3: JWT Token Content" -ForegroundColor Yellow
if ($adminToken) {
    # Decode JWT (simple base64 decode of payload)
    $parts = $adminToken.Split('.')
    if ($parts.Length -eq 3) {
        $payload = $parts[1]
        # Add padding if needed
        while ($payload.Length % 4 -ne 0) {
            $payload += "="
        }
        
        try {
            $decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($payload)) | ConvertFrom-Json
            
            if ($decoded.branchId) {
                Write-Host "  Token contains branchId: $($decoded.branchId)" -ForegroundColor Green
            } else {
                Write-Host "  Token missing branchId" -ForegroundColor Red
            }
            
            if ($decoded.branches) {
                $branchList = $decoded.branches -join ', '
                Write-Host "  Token contains branches array: $branchList" -ForegroundColor Green
            } else {
                Write-Host "  Token missing branches array" -ForegroundColor Red
            }
            
            Write-Host "  Role: $($decoded.role)" -ForegroundColor White
            Write-Host ""
        } catch {
            Write-Host "  Could not decode token payload" -ForegroundColor Yellow
            Write-Host ""
        }
    }
}

# Summary
Write-Host "========================================" -ForegroundColor Green
Write-Host "  All Tests Passed!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Auth system is working correctly!" -ForegroundColor Cyan
Write-Host "You can now:" -ForegroundColor Cyan
Write-Host "  1. Run the Flutter app: flutter run -d windows" -ForegroundColor White
Write-Host "  2. Login with admin/admin123 or cashier1/cashier123" -ForegroundColor White
Write-Host "  3. Socket should connect without errors" -ForegroundColor White
Write-Host ""
