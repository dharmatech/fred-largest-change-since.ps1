
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

# $result = get-fred-series 'BOGZ1FL404090430Q'

# $table = delta $result BOGZ1FL404090430Q

# ----------------------------------------------------------------------

# $table = $result

# ----------------------------------------------------------------------

function reverse
{ 
    $arr = @($input)
    [array]::reverse($arr)
    $arr
}

# $reversed = $table | reverse

# # $i = 0

# $prop = 'BOGZ1FL404090430Q_change'



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

# $updated = calc-days-since-larger-change $result BOGZ1FL404090430Q

# ----------------------------------------------------------------------

# $result = get-fred-series 'WALCL'
# $updated = calc-days-since-larger-change $result 'WALCL'

# $updated

# ----------------------------------------------------------------------

function get-and-calc-days-since-larger-change ($series)
{
    $result = get-fred-series $series
    $updated = calc-days-since-larger-change $result $series
    
    $updated       
}

# ----------------------------------------------------------------------

# $table = get-and-calc-days-since-larger-change WLODLL

# $table[-1]

# ----------------------------------------------------------------------
# H.4.1 table 5 with loans expanded from table 1
# ----------------------------------------------------------------------

function h41 ()
{
    $ls = @(
        'WLFN'
        'WLRRAL'
        'TERMT'
        'WLODLL'
        'WDTGAL'
        'WDFOL'
        'WLODL'
        'H41RESH4ENWW'
        'WLDACLC'
        'WLAD'
        'WSHOBL'
        'WSHONBNL'
        'WSHONBIIL'
        'WSHOICL'
        'WSHOFADSL'
        'WSHOMCB'
        'WUPSHO'
        'WUDSHO'
        'WORAL'
        'SWPT'
        'WFCDA'
        'WAOAL'
        'WLCFLPCL'
        'WLCFLSCL'
        'WLCFLSECL'
        'H41RESPPALDJNWW'
        'WLCFOCEL'
        'H41RESPPALDKNWW'
    )
        
    $series_tables = @{}

    foreach ($series in $ls)
    {
        $series_tables[$series] = get-fred-series $series
    }
       
    $all_result_a = foreach ($entry in $series_tables.GetEnumerator())
    {
        Write-Host ('{0}' -f $entry.Name) -ForegroundColor Yellow
        $series = $entry.Name
        $table = $entry.Value
    
        $result = calc-days-since-larger-change $table $series
    
        $result[-1]
    }
    
    $all_result_a | Select-Object DATE, prop, days | Sort-Object days | ft    
}


# $results_all = foreach ($series in $ls)
# {
#     $table = get-and-calc-days-since-larger-change $series

#     $table[-1]    
# }

# $results_all | Format-Table 
# ----------------------------------------------------------------------



# ----------------------------------------------------------------------
# H.8 not seasonally adjusted
# 
# https://fred.stlouisfed.org/release/tables?rid=22&eid=822963
# ----------------------------------------------------------------------

function h8-not-seasonally-adjusted () {

    $ls = @(
        'LTDACBW027NBOG'
        'ODSACBW027NBOG'
        'NDFACBW027NBOG'
        'H8B3094NCBD'
        'H8B3095NCBD'
        'TMBACBW027NBOG'
        'TNMACBW027NBOG'
        'OMBACBW027NBOG'
        'ONMACBW027NBOG'
        'TOTCINSA'
        'RHEACBW027NBOG'
        'CRLACBW027NBOG'
        'CCLACBW027NBOG'
        'ALLACBW027NBOG'
        'CASACBW027NBOG'
        'LCBACBW027NBOG'
        'CLDACBW027NBOG'
        'SBFACBW027NBOG'
        'SMPACBW027NBOG'
        'SNFACBW027NBOG'
        'AOCACBW027NBOG'
        'CARACBW027NBOG'
        'LNFACBW027NBOG'
        'OLNACBW027NBOG'
        'H8B3092NCBD'
        'H8B3053NCBD'
    )

    $series_tables = @{}

    foreach ($series in $ls)
    {
        $series_tables[$series] = get-fred-series $series
    }
       
    $all_result_a = foreach ($entry in $series_tables.GetEnumerator())
    {
        Write-Host ('{0}' -f $entry.Name) -ForegroundColor Yellow
        $series = $entry.Name
        $table = $entry.Value
    
        $result = calc-days-since-larger-change $table $series
    
        $result[-1]
    }
    
    $all_result_a | Select-Object DATE, prop, days | Sort-Object days | ft        
}

# ----------------------------------------------------------------------

# H.8 seasonally adjusted

# https://fred.stlouisfed.org/release/tables?rid=22&eid=822916

# https://fred.stlouisfed.org/series/TMBACBW027SBOG
# https://fred.stlouisfed.org/series/TNMACBW027SBOG
# https://fred.stlouisfed.org/series/OMBACBW027SBOG
# https://fred.stlouisfed.org/series/ONMACBW027SBOG
# https://fred.stlouisfed.org/series/TOTCI
# https://fred.stlouisfed.org/series/RHEACBW027SBOG
# https://fred.stlouisfed.org/series/CRLACBW027SBOG
# https://fred.stlouisfed.org/series/CLDACBW027SBOG
# https://fred.stlouisfed.org/series/SBFACBW027SBOG
# https://fred.stlouisfed.org/series/SMPACBW027SBOG
# https://fred.stlouisfed.org/series/SNFACBW027SBOG
# https://fred.stlouisfed.org/series/CCLACBW027SBOG
# https://fred.stlouisfed.org/series/CARACBW027SBOG
# https://fred.stlouisfed.org/series/AOCACBW027SBOG
# https://fred.stlouisfed.org/series/LNFACBW027SBOG
# https://fred.stlouisfed.org/series/OLNACBW027SBOG
# https://fred.stlouisfed.org/series/ALLACBW027SBOG
# https://fred.stlouisfed.org/series/CASACBW027SBOG
# https://fred.stlouisfed.org/series/H8B3092NCBA
# https://fred.stlouisfed.org/series/LCBACBW027SBOG
# https://fred.stlouisfed.org/series/H8B3053NCBA
# https://fred.stlouisfed.org/series/LTDACBW027SBOG
# https://fred.stlouisfed.org/series/ODSACBW027SBOG
# https://fred.stlouisfed.org/series/H8B3094NCBA
# https://fred.stlouisfed.org/series/NDFACBW027SBOG
# https://fred.stlouisfed.org/series/H8B3095NCBA


function h8-seasonally-adjusted () {

    $ls = @(
        'TMBACBW027SBOG'
        'TNMACBW027SBOG'
        'OMBACBW027SBOG'
        'ONMACBW027SBOG'
        'TOTCI'
        'RHEACBW027SBOG'
        'CRLACBW027SBOG'
        'CLDACBW027SBOG'
        'SBFACBW027SBOG'
        'SMPACBW027SBOG'
        'SNFACBW027SBOG'
        'CCLACBW027SBOG'
        'CARACBW027SBOG'
        'AOCACBW027SBOG'
        'LNFACBW027SBOG'
        'OLNACBW027SBOG'
        'ALLACBW027SBOG'
        'CASACBW027SBOG'
        'H8B3092NCBA'
        'LCBACBW027SBOG'
        'H8B3053NCBA'
        'LTDACBW027SBOG'
        'ODSACBW027SBOG'
        'H8B3094NCBA'
        'NDFACBW027SBOG'
        'H8B3095NCBA'
    )
        
    $series_tables = @{}

    foreach ($series in $ls)
    {
        $series_tables[$series] = get-fred-series $series
    }
       
    $all_result_a = foreach ($entry in $series_tables.GetEnumerator())
    {
        Write-Host ('{0}' -f $entry.Name) -ForegroundColor Yellow
        $series = $entry.Name
        $table = $entry.Value
    
        $result = calc-days-since-larger-change $table $series
    
        $result[-1]
    }
    
    $all_result_a | Select-Object DATE, prop, days | Sort-Object days | ft        
}

exit
# ----------------------------------------------------------------------
h41
h8-not-seasonally-adjusted
h8-seasonally-adjusted