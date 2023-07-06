
function download-fred-series ($series, $date)
{
    Write-Host ('Downloading {0} series since: {1}' -f $series, $date) -ForegroundColor Yellow
    $result = Invoke-RestMethod ('https://fred.stlouisfed.org/graph/fredgraph.csv?id={0}&cosd={1}' -f $series, $date)
    $data = @($result | ConvertFrom-Csv)
    Write-Host ('Received {0} items' -f $data.Count) -ForegroundColor Yellow
    $data
}

function get-fred-series-raw ($series, $date)
{
    $path = ("{0}.json" -f $series)

    if (Test-Path $path)
    {
        $data = Get-Content $path | ConvertFrom-Json
        $last_date = $data[-1].DATE
        $result = download-fred-series $series $last_date
        $items = @($result | Where-Object DATE -gt $last_date)

        if ($items.Count -gt 0)
        {
            Write-Host ('Adding {0} items' -f $items.Count) -ForegroundColor Yellow
            $new = $data + $items
            $new | ConvertTo-Json > $path
            $new
        }
        else
        {
            Write-Host 'No new items found' -ForegroundColor Yellow
            $data
        }
    }
    else
    {
        $result = download-fred-series $series $date
        $result | ConvertTo-Json > $path
        $result
    }
}

function get-fred-series ($series, $date = '1800-01-01')
{
    $result = get-fred-series-raw $series $date

    $result = $result | Where-Object $series -NE '.'

    foreach ($row in $result)
    {
        $row.$series = [decimal] $row.$series
    }

    $result | Sort-Object DATE 
}

function delta ($table, $a, $b)
{
    if ($b -eq $null)
    {
        $b = '{0}_change' -f $a
    }

    $prev = $table[0]

    foreach ($elt in $table | Select-Object -Skip 1)
    {
        $change = $elt.$a - $prev.$a

        $elt | Select-Object *, @{ Label = $b; Expression = { $change } }

        $prev = $elt
    }
}

# ----------------------------------------------------------------------

$result = get-fred-series 'BOGZ1FL404090430Q'

$table = delta $result BOGZ1FL404090430Q

# ----------------------------------------------------------------------

# $table = $result

# ----------------------------------------------------------------------

function reverse
{ 
    $arr = @($input)
    [array]::reverse($arr)
    $arr
}

$reversed = $table | reverse

# $i = 0

$prop = 'BOGZ1FL404090430Q_change'



# ----------------------------------------------------------------------

# function calc-days-since-larger-change-aux ($reversed, $prop)
# {
#     for ($i = 0; $i -lt $reversed.Count; $i++)
#     {
#         $curr = $reversed[$i]
#         $rest = $reversed[($i+1)..($reversed.Count-1)]
    
#         if ($curr.$prop -gt 0)
#         {
#             $others = @($rest | ? $prop -GT $curr.$prop)

#             # $result_where = $rest.where( { $_.$prop -gt $curr.$prop }, 'First' )

#             # $result_where = $rest.where( { $_.$prop -gt 1000000000 }, 'First' )


    
#             if ($others.Count -eq 0)
#             {
#                 $curr | Add-Member -MemberType NoteProperty -Name days -Value 99999
                
#                 $curr | Add-Member -MemberType NoteProperty -Name prop -Value $prop
#             }
#             else
#             {
#                 $other = $others[0]
    
#                 $curr | Add-Member -MemberType NoteProperty -Name days -Value ((Get-Date $curr.DATE) - (Get-Date $other.DATE)).TotalDays

#                 $curr | Add-Member -MemberType NoteProperty -Name prop -Value $prop
#             }
#         }
#         elseif ($curr.$prop -lt 0)
#         {
#             $others = @($rest | ? $prop -LT $curr.$prop)
    
#             if ($others.Count -eq 0)
#             {
#                 $curr | Add-Member -MemberType NoteProperty -Name days -Value 99999

#                 $curr | Add-Member -MemberType NoteProperty -Name prop -Value $prop
#             }
#             else
#             {
#                 $other = $others[0]
                
#                 $curr | Add-Member -MemberType NoteProperty -Name days -Value ((Get-Date $curr.DATE) - (Get-Date $other.DATE)).TotalDays

#                 $curr | Add-Member -MemberType NoteProperty -Name prop -Value $prop
#             }
#         }
#     }    
# }

function calc-days-since-larger-change-aux ($reversed, $prop)
{
    for ($i = 0; $i -lt $reversed.Count; $i++)
    {
        $curr = $reversed[$i]
        $rest = $reversed[($i+1)..($reversed.Count-1)]
    
        $curr | Add-Member -MemberType NoteProperty -Name prop -Value $prop

        if ($curr.$prop -gt 0)
        {
            $others = $rest.where( { $_.$prop -gt $curr.$prop }, 'First' )
        }
        elseif ($curr.$prop -lt 0)
        {
            $others = $rest.where( { $_.$prop -lt $curr.$prop }, 'First' )
        }
        else
        {
            continue
        }

        if ($others.Count -eq 0)
        {
            $curr | Add-Member -MemberType NoteProperty -Name days -Value 99999
        }
        else
        {
            $other = $others[0]

            $curr | Add-Member -MemberType NoteProperty -Name days -Value ((Get-Date $curr.DATE) - (Get-Date $other.DATE)).TotalDays
        }
    }    
}




function calc-days-since-larger-change ($result, $prop)
{
    $table = delta $result $prop

    $reversed = $table | reverse

    $prop_change = $prop + '_change'

    calc-days-since-larger-change-aux $reversed $prop_change

    $table
}

# ----------------------------------------------------------------------

$updated = calc-days-since-larger-change $result BOGZ1FL404090430Q

# ----------------------------------------------------------------------

$result = get-fred-series 'WALCL'
$updated = calc-days-since-larger-change $result 'WALCL'

$updated

# ----------------------------------------------------------------------

function get-and-calc-days-since-larger-change ($series)
{
    $result = get-fred-series $series
    $updated = calc-days-since-larger-change $result $series
    
    $updated       
}

# ----------------------------------------------------------------------

$table = get-and-calc-days-since-larger-change WLODLL

$table[-1]

# ----------------------------------------------------------------------

$items = @"
WLFN
WLRRAL
TERMT
WLODLL
WDTGAL
WDFOL
WLODL
H41RESH4ENWW
WLDACLC
WLAD
WSHOBL
WSHONBNL
WSHONBIIL
WSHOICL
WSHOFADSL
WSHOMCB
WUPSHO
WUDSHO
WORAL
SWPT
WFCDA
WAOAL
WLCFLPCL
WLCFLSCL
WLCFLSECL
H41RESPPALDJNWW
WLCFOCEL
H41RESPPALDKNWW
"@

$ls = $items -split "`r`n"

$results_all = foreach ($series in $ls)
{
    $table = get-and-calc-days-since-larger-change $series

    $table[-1]    
}

$results_all | Format-Table 
# ----------------------------------------------------------------------

$series_tables = @{}

foreach ($series in $ls)
{
    $series_tables[$series] = get-fred-series $series
}


$all_result_a = foreach ($entry in $series_tables.GetEnumerator())
{
    $series = $entry.Name
    $table = $entry.Value

    $result = calc-days-since-larger-change $table $series

    $result[-1]
}

$all_result_a | Select-Object DATE, prop, days | Sort-Object days | ft