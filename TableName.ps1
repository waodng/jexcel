$constr = 'server=.;database=XHCSSD60DB;user=sa;password=Wqkj123'
#sql连接实例化
$con = new-object Data.SqlClient.SqlConnection($constr)
#sql连接打开
if($con.State -eq [Data.ConnectionState]::Closed)
{
    $con.Open()
}

#sql语句
$sql = "SELECT 
            Id              = a.colorder,
            TableName = t.name,
            ColName     = a.name,
            DataType       = b.name,
            MaxLength       = COLUMNPROPERTY(a.id,a.name,'PRECISION'),
            DecimalNum   = isnull(COLUMNPROPERTY(a.id,a.name,'Scale'),0),
            AutoIncrement       = case when COLUMNPROPERTY( a.id,a.name,'IsIdentity')=1 then '1'else '' end,
            AllowDBNull     = case when a.isnullable=1 then '1'else '' end,
            DefaultValue     = isnull(e.text,''),
            Comments   = isnull(g.[value],''),
            IsPrimaryKey       = case when exists(SELECT 1 FROM sysobjects where xtype='PK' and parent_obj=a.id and name in (
                            SELECT name FROM sysindexes WHERE indid in(
                                SELECT indid FROM sysindexkeys WHERE id = a.id AND colid=a.colid))) then '1' else '' end
        FROM sys.tables t
        inner join syscolumns a on t.object_id=a.id
        left join systypes b on a.xusertype=b.xusertype
        inner join sysobjects d on a.id=d.id  and d.xtype='U' and  d.name<>'dtproperties'
        left join syscomments e on  a.cdefault=e.id
        left join sys.extended_properties g on a.id=g.major_id and a.colid=g.minor_id  
        order by a.id,a.colorder"
        
#Command实例创建
$cmd = new-object Data.SqlClient.SqlCommand($sql,$con)
$adapter = new-object Data.SqlClient.SqlDataAdapter($cmd)
$tableInfo = new-object Data.DataTable
$adapter.Fill($tableInfo)

Write-Host('表列数据获取成功')
#$tableInfo | Format-Table

if($con.State -eq [Data.ConnectionState]::Open)
{
    $con.Close()
}

Write-Host('开始解析数据...')
 #$tableInfo | ConvertTo-Csv
$newTable = $tableInfo.Clone()
foreach($item in $tableInfo)
{
    if($item.Id -eq 1)
    {
        $dr = $newTable.NewRow()
        $dr.ColName= '表名：'+$item.TableName
        $newTable.Rows.Add($dr)
    }
    $newTable.ImportRow($item)
}
#移除不需要的列信息
$newTable.Columns.Remove("Id")
$newTable.Columns.Remove("TableName")
#$newTable | Format-Table
Write-Warning("解析数据完成...开始生成csv文件..")
#$newTable | Select-Object -first 3 | Format-Table 
#$newTable | Export-Csv tableInfo.csv -NoTypeInformation -Encoding utf8 
$newTable | ConvertTo-Csv -NoTypeInformation | Select-Object -Skip 1 |Set-Content -Encoding utf8 -Path tableInfo.csv 

#($tableInfo | select $tableInfo.Columns.ColumnName) | ConvertTo-Json | Set-Content -Encoding UTF8 -Path Temp.json
#$newTable | ConvertTo-Html | Select-Object -Skip 1 |Set-Content -Encoding utf8 -Path tableInfo.html 

Write-Warning("文件tableInfo.csv数据保存成功。。")

if(Test-Path .git)
{
    echo 'git commit..'
    git add 'tableInfo.csv'
    git commit -m 'table name json is upload..'
    git push origin master
    Write-Warning('git upload is success..')
}
else
{
    Write-Host( 'git dir not exitst')
}

