function AddServices($path)
{
    $filename = $path
    $updatedContent = @()
    Get-Content -Path $filename | ForEach-Object {
    if ($_ -like '*<Compile Include="Startup.dbl" />*')
    {
        $updatedContent += '<Compile Include="PrimaryKeyGenerator.dbl" />'
        $updatedContent += '<Compile Include="StartupCustom.dbl" />'
    }
    $updatedContent += $_
    }
    $updatedContent | Set-Content $filename
}

function UpdateHost($path)
{
    $filename =  $path
    $updatedContent = @()
    Get-Content -Path $filename | ForEach-Object {
    if ($_ -like '*dispatcher = new SuperRoutineDispatcher(MethodDispatcher.GetDispatchers())*')
    {
        $updatedContent += 'dispatcher = new SuperRoutineDispatcher(new RoutineDispatcher[#] { new BridgeMethodsDispatcher() })'
    }
    else
    {
        $updatedContent += $_
    }
    }
    $updatedContent | Set-Content $filename
}

function UpdateTbPlatform($path)
{
    $guid = 'empty'
    $filename = $path
    $updatedContent = @()
    Get-Content -Path $filename | ForEach-Object {
    if ($_ -like '*TraditionalBridge\TraditionalBridge.synproj*') {	
        $guid = $_ -split ',' | Select-String -Pattern '\{.*\}' -AllMatches | % { $_.Matches } | % { $_.Value } | Select-Object -Last 1
    }
    if ($_ -like "*$guid*" -and ($_ -like "*Any CPU.ActiveCfg*" -or $_ -like "*Any CPU.Build.0*")) {
        $lastIndex = $_.LastIndexOf("Any CPU")
        $replacedplatform = $_.Substring(0, $lastIndex) + "x64" + $_.Substring($lastIndex + "Any CPU".Length)
        $_ = $replacedplatform 
    }
    $updatedContent += $_
    }
    $updatedContent | Set-Content $filename
}

function UpdateTbOutput($path)
{
    $filename = $path
    $updatedContent = @()
    Get-Content -Path $filename | ForEach-Object {
    if ($_ -like '*<OutputPath>*') {
        $_ = '<OutputPath>$(SolutionDir)TBEXE\$(Configuration)</OutputPath>'
    }
    if ($_ -like '*<UnevaluatedOutputPath>*') {
        $_ = '<UnevaluatedOutputPath>$(SolutionDir)TBEXE\$(Configuration)</UnevaluatedOutputPath>'
    }
    $updatedContent += $_
    }
    $updatedContent | Set-Content $filename
}

function AddMethodsTb($path)
{
    $filename =  $path
    $updatedContent = @()
    Get-Content -Path $filename | ForEach-Object {
    if ($_ -like '*<Compile Include="Source\host.dbl" />*')
    {
        $updatedContent += '<Compile Include="Source\Methods\AddTwoNumbers.dbl" />'
        $updatedContent += '<Compile Include="Source\Methods\GetEnvironment.dbl" />'
        $updatedContent += '<Compile Include="Source\Methods\GetLogicalName.dbl" />'
    }
    $updatedContent += $_
    }
    $updatedContent | Set-Content $filename
}

function AddMethodsTbStruct($path)
{
    $filename =  $path
    $updatedContent = @()
    Get-Content -Path $filename | ForEach-Object {
    if ($_ -like '*<Compile Include="Source\host.dbl" />*')
    {
        $updatedContent += '<Compile Include="Source\Methods\GetAllCustomers.dbl" />'
        $updatedContent += '<Compile Include="Source\Methods\GetCustomer.dbl" />'
        $updatedContent += '<Compile Include="Source\Methods\ManyCustomers.dbl" />'
        $updatedContent += '<Compile Include="Source\Methods\OneCustomer.dbl" />'
        $updatedContent += '<Compile Include="Source\Methods\ReturnCustomer.dbl" />'
    }
    $updatedContent += $_
    }
    $updatedContent | Set-Content $filename
}

function SetCreateTestFiles($path)
{
$options=@'
,
"CreateTestFiles": true
}
'@
    $filename = $path
    $file = Get-Content $filename
    if ($file[$file.length - 1] -eq '}') 
    {
        $file[$file.length - 1] = $options
        $file | Set-Content $filename	
    }
}

function SetOdataBasic($path)
{
$options=@'
,
"FullCollectionEndpoints": true,
"PrimaryKeyEndpoints": true,
"AlternateKeyEndpoints": true,
"CollectionCountEndpoints": true,
"IndividualPropertyEndpoints": true,
"PutEndpoints": true,
"PostEndpoints": true,
"PatchEndpoints": true,
"DeleteEndpoints": true,
"ODataSelect": true,
"ODataFilter": true,
"ODataOrderBy": true,
"ODataTop": true,
"ODataSkip": true,
"ODataRelations": true,
"ODataRelationValidation": true,
"CreateTestFiles": true,
"GenerateUnitTests": true,
"DocumentPropertyEndpoints": true,
"GenerateOData": true
}
'@
    $filename = $path
    $file = Get-Content $filename
    if ($file[$file.length - 1] -eq '}') 
    {
        $file[$file.length - 1] = $options
        $file | Set-Content $filename	
    }
}

function EnableAuth($path)
{
$options=@'
,
"Authentication": true,
"CustomAuthentication": true
}
'@
    $filename = $path
    $file = Get-Content $filename
    if ($file[$file.length - 1] -eq '}') 
    {
        $file[$file.length - 1] = $options
        $file | Set-Content $filename	
    }
}

function TestTb($path)
{
    $path = $path -replace "\\$"
    $env:solutiondir="$path\"
    $env:exedir="${env:solutiondir}tbexe\release"
    cd ${env:solutiondir}Services.Host
    dotnet dev-certs https --clean
    $process = start-process powershell '-c', {dotnet run} -passthru -NoNewWindow
    sleep 120
    $res = curl.exe https://localhost:8086/BridgeMethods/AddTwoNumbers -k -X POST -H "Content-Type: application/json" -d '{ "number1": 1, "number2":2 }'
    taskkill /f /pid $process.id /t
    $res
    if ($res -ne '{"result":3.0000000000}') 
    {
        echo "Error occured during POST request"
        exit -1 
    }         
}

function TestTbStruct($path)
{
    $path = $path -replace "\\$"
    $env:solutiondir="$path\"
    $env:exedir="${env:solutiondir}tbexe\release"
    cd ${env:solutiondir}Services.Host
    dotnet dev-certs https --clean
    $process = start-process powershell '-c', {dotnet run} -passthru -NoNewWindow
    sleep 120
    echo "Test GetAllCustomers endpoint"
    $res1 = curl.exe https://localhost:8086/BridgeMethods/GetAllCustomers -k -X GET -H "Content-Type: application/json"
    $res1

    echo "Test GetCustomer endpoint"
    $res2 = curl.exe https://localhost:8086/BridgeMethods/GetCustomer -k -X POST -H "Content-Type: application/json" -d '{ "id": 1 }'
    $res2

    echo "Test ReturnCustomer endpoint"
    $res3 = curl.exe https://localhost:8086/BridgeMethods/ReturnCustomer -k -X POST -H "Content-Type: application/json" -d '{ "id": 1 }'
    $res3

    echo "Test OneCustomer endpoint"
    $res4DataReq = $res2 | convertfrom-json
    $res4DataReq = $res4DataReq.cust
    $res4DataReq = $res4DataReq | convertto-json
    $res4DataReq = $res4DataReq -replace "\r\n", ""
    $res4DataReq = $res4DataReq -replace "`"", "\`""
    $res4 = curl.exe https://localhost:8086/BridgeMethods/OneCustomer -k -X POST -H "Content-Type: application/json" -d "{`"cust`": $res4DataReq}"
    $res4

    echo "Test ManyCustomers endpoint"
    $res5DataReq = $res1 | convertfrom-json
    $res5DataReq = $res5DataReq.cust
    $res5DataReq = $res5DataReq | convertto-json
    $res5DataReq = $res5DataReq -replace "\r\n", ""
    $res5DataReq = $res5DataReq -replace "`"", "\`""
    $res5 = curl.exe https://localhost:8086/BridgeMethods/ManyCustomers -k -X POST -H "Content-Type: application/json" -d "{`"cust`": $res5DataReq}"
    $res5

    taskkill /f /pid $process.id /t

    echo "Verify requests"
    
    echo "GetAllCustomers Test"
    $res1 = $res1 | convertfrom-json
    if ($res1.ReturnValue -ne 0 -or $res1.errorMessage -ne "")
    {
        echo "Error occured with GetAllCustomers endpoint"
        exit -1
    }
    else
    {
        echo "Passed"
    }

    echo "GetCustomer Test"
    $res2 = $res2 | convertfrom-json
    if ($res2.ReturnValue -ne 0 -or $res2.errorMessage -ne "")
    {
        echo "Error occured with GetCustomer endpoint"
        exit -1
    }
    else
    {
        echo "Passed"
    }

    echo "ReturnCustomer Test"
    $res3 = $res3 | convertfrom-json
    if ($res3.ReturnValue -eq "" -or $res3.errorMessage -ne "")
    {
        echo "Error occured with ReturnCustomer endpoint"
        exit -1
    }
    else
    {
        echo "Passed"
    }

    echo "OneCustomer Test"
    $res4 = $res4 | convertfrom-json
    if ($res4.ReturnValue -ne "found" -or $res4.errorMessage -ne "")
    {
        echo "Error occured with OneCustomer endpoint"
        exit -1
    }
    else
    {
        echo "Passed"
    }

    echo "ManyCustomers Test"
    $res5 = $res5 | convertfrom-json
    if ($res5.ReturnValue -ne "equal" -or $res5.errorMessage -ne "")
    {
        echo "Error occured with ManyCustomers endpoint"
        exit -1
    }
    else
    {
        echo "Passed"
    }
}

function TestTbAuth($path)
{
    $path = $path -replace "\\$"
    $env:solutiondir="$path\"
    $env:exedir="${env:solutiondir}tbexe\release"
    cd ${env:solutiondir}Services.Host
    dotnet dev-certs https --clean
    $process = start-process powershell '-c', {dotnet run} -passthru -NoNewWindow
    sleep 120
    $token = curl.exe https://localhost:8086/Authentication/GetToken -k -X POST -H "Content-Type: application/json" -d '{ \"Username\": \"username\", \"Password\": \"password\" }'
    $res = curl.exe https://localhost:8086/BridgeMethods/AddTwoNumbers -k -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $token" -d '{ "number1": 1, "number2":2 }'
    $res
    if ($res -ne '{"result":3.0000000000}') 
    {
        echo "Error occured during POST request"
        taskkill /f /pid $process.id /t
        exit -1 
    }
    $res = curl.exe https://localhost:8086/BridgeMethods/AddTwoNumbers -k -X POST -H "Content-Type: application/json" -d '{ "number1": 1, "number2":2 }'
    $res
    if ($res -ne $null) 
    {
        echo "Error response should be null"
        taskkill /f /pid $process.id /t
        exit -1 
    }
    $res = curl.exe https://localhost:8086/BridgeMethods/AddTwoNumbers -k -X POST -H "Content-Type: application/json" -H "Authorization: Bearer hello" -d '{ "number1": 1, "number2":2 }'
    $res
    if ($res -ne $null) 
    {
        echo "Error response should be null"
        taskkill /f /pid $process.id /t
        exit -1 
    }
    taskkill /f /pid $process.id /t   
}

function TestTbStructAuth($path)
{
    $path = $path -replace "\\$"
    $env:solutiondir="$path\"
    $env:exedir="${env:solutiondir}tbexe\release"
    cd ${env:solutiondir}Services.Host
    dotnet dev-certs https --clean
    $process = start-process powershell '-c', {dotnet run} -passthru -NoNewWindow
    sleep 120
    echo "Get Auth Token"
    $token = curl.exe https://localhost:8086/Authentication/GetToken -k -X POST -H "Content-Type: application/json" -d '{ \"Username\": \"username\", \"Password\": \"password\" }'
    echo "Test GetAllCustomers endpoint"
    $res1 = curl.exe https://localhost:8086/BridgeMethods/GetAllCustomers -k -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $token"
    $res1

    echo "Test GetCustomer endpoint"
    $res2 = curl.exe https://localhost:8086/BridgeMethods/GetCustomer -k -X POST -H "Content-Type: application/json" -d '{ "id": 1 }' -H "Authorization: Bearer $token"
    $res2

    echo "Test ReturnCustomer endpoint"
    $res3 = curl.exe https://localhost:8086/BridgeMethods/ReturnCustomer -k -X POST -H "Content-Type: application/json" -d '{ "id": 1 }' -H "Authorization: Bearer $token"
    $res3

    echo "Test OneCustomer endpoint"
    $res4DataReq = $res2 | convertfrom-json
    $res4DataReq = $res4DataReq.cust
    $res4DataReq = $res4DataReq | convertto-json
    $res4DataReq = $res4DataReq -replace "\r\n", ""
    $res4DataReq = $res4DataReq -replace "`"", "\`""
    $res4 = curl.exe https://localhost:8086/BridgeMethods/OneCustomer -k -X POST -H "Content-Type: application/json" -d "{`"cust`": $res4DataReq}" -H "Authorization: Bearer $token"
    $res4

    echo "Test ManyCustomers endpoint"
    $res5DataReq = $res1 | convertfrom-json
    $res5DataReq = $res5DataReq.cust
    $res5DataReq = $res5DataReq | convertto-json
    $res5DataReq = $res5DataReq -replace "\r\n", ""
    $res5DataReq = $res5DataReq -replace "`"", "\`""
    $res5 = curl.exe https://localhost:8086/BridgeMethods/ManyCustomers -k -X POST -H "Content-Type: application/json" -d "{`"cust`": $res5DataReq}" -H "Authorization: Bearer $token"
    $res5

    taskkill /f /pid $process.id /t

    echo "Verify requests"

    echo "GetAllCustomers Test"
    $res1 = $res1 | convertfrom-json
    if ($res1.ReturnValue -ne 0 -or $res1.errorMessage -ne "")
    {
        echo "Error occured with GetAllCustomers endpoint"
        exit -1
    }
    else
    {
        echo "Passed"
    }

    echo "GetCustomer Test"
    $res2 = $res2 | convertfrom-json
    if ($res2.ReturnValue -ne 0 -or $res2.errorMessage -ne "")
    {
        echo "Error occured with GetCustomer endpoint"
        exit -1
    }
    else
    {
        echo "Passed"
    }

    echo "ReturnCustomer Test"
    $res3 = $res3 | convertfrom-json
    if ($res3.ReturnValue -eq "" -or $res3.errorMessage -ne "")
    {
        echo "Error occured with ReturnCustomer endpoint"
        exit -1
    }
    else
    {
        echo "Passed"
    }

    echo "OneCustomer Test"
    $res4 = $res4 | convertfrom-json
    if ($res4.ReturnValue -ne "found" -or $res4.errorMessage -ne "")
    {
        echo "Error occured with OneCustomer endpoint"
        exit -1
    }
    else
    {
        echo "Passed"
    }

    echo "ManyCustomers Test"
    $res5 = $res5 | convertfrom-json
    if ($res5.ReturnValue -ne "equal" -or $res5.errorMessage -ne "")
    {
        echo "Error occured with ManyCustomers endpoint"
        exit -1
    }
    else
    {
        echo "Passed"
    }
}

if ($args[0])
{
    switch($args[0])
    {
        AddServices 
        {
            if ($args[1])
            {
                AddServices($args[1])
            }
        }
        UpdateHost
        {
            if ($args[1])
            {
                UpdateHost($args[1])
            }
        }
        UpdateTbPlatform
        {
            if ($args[1])
            {
                UpdateTbPlatform($args[1])
            }
        }
        UpdateTbOutput
        {
            if ($args[1])
            {
                UpdateTbOutput($args[1])
            }
        }
        AddMethodsTb
        {
            if ($args[1])
            {
                AddMethodsTb($args[1])
            }
        }
        AddMethodsTbStruct
        {
            if ($args[1])
            {
                AddMethodsTbStruct($args[1])
            }
        }
        SetCreateTestFiles
        {
            if ($args[1])
            {
                SetCreateTestFiles($args[1])
            }
        }
        SetOdataBasic
        {
            if ($args[1])
            {
                SetOdataBasic($args[1])
            }
        }
        EnableAuth
        {
            if ($args[1])
            {
                EnableAuth($args[1])
            }
        }
        TestTb
        {
          if ($args[1])
            {
                TestTb($args[1])
            }  
        }
        TestTbStruct
        {
            if ($args[1])
            {
                TestTbStruct($args[1])
            }
        }
        TestTbAuth
        {
           if ($args[1])
            {
                TestTbAuth($args[1])
            } 
        }
        TestTbStructAuth
        {
            if ($args[1])
            {
                TestTbStructAuth($args[1])
            }
        }
    }
}
else
{
    echo "No arguments passed"  
}