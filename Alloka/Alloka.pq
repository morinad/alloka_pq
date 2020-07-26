
section Alloka;

[DataSource.Kind="Alloka", Publish="Alloka.Publish"]
shared Alloka.Data = Value.ReplaceType(Alloka.Func, FuncType);

FuncType = type function (
     
    object_id as (type text meta [        
        Documentation.FieldCaption = "Alloka account ID:",
         Documentation.SampleValues = {"g3J8j9LJ0jfa10gK"}
    ]),

    start as (type text meta [
        Documentation.FieldCaption = "Start date:",
        Documentation.FieldDescription = "Enter the first date of your statistics. You can specify date in YYYY-MM-DD format or use dynamic formats: today, yesterday, 69daysAgo.",
        Documentation.SampleValues = {"2020-02-28"}
    ]),
     
     end as (type text meta [
        Documentation.FieldCaption = "End date:",
        Documentation.FieldDescription = "Enter the last date of your statistics. You can specify date in YYYY-MM-DD format or use dynamic formats: today, yesterday, 69daysAgo.",
        Documentation.SampleValues = {"yesterday"}
    ])
    )
    as table meta [
        Documentation.Name = "Alloka.Data Function",
        Documentation.LongDescription = "Created to get data from Alloka.",
        Documentation.Examples = {
        [
            Description = "Returns a list of records from your Alloka table",
            Code = "Alloka.Data(""2020-02-20"",""yesterday"")",
            Result = "{[Record1],[Record2],[Record3],...}"
        ],
        [
            Description = "Returns a list of records from your Alloka table",
            Code = "Alloka.Data(""500daysAgo"",""today"")",
            Result = "{[Record1],[Record2],[Record3],...}"
        ]
        }
    ];



Alloka.Func =( object_id as text, start as text, end as text)=>
let
url = "https://api.alloka.ru/v2/objs/"& object_id &"/calls",
    period = "custom",
    Query = [date_from = dateFunc(start), date_to = dateFunc(end), period = period],
    Source = Json.Document(Web.Contents(url , [Headers=[#"X-AUTH-TOKEN"=Extension.CurrentCredential()[Key], #"Content-Type"="application/json"], Query = Query])),
    met = Source[meta],
    pagination = met[pagination],
    List = List.Numbers(1,pagination[total_pages],1),
    #"Converted to Table" = Table.FromList(List, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Changed Type" = Table.TransformColumnTypes(#"Converted to Table",{{"Column1", type text}}),
    #"Renamed Columns" = Table.RenameColumns(#"Changed Type",{{"Column1", "page"}}),
    #"Added Custom" = Table.AddColumn(#"Renamed Columns", "query", each [date_from = dateFunc(start), date_to = dateFunc(end), period = period, page = [page]]),
    #"Added Custom1" = Table.AddColumn(#"Added Custom", "Custom", each Json.Document(Web.Contents(url , [Headers=[#"X-AUTH-TOKEN"=Extension.CurrentCredential()[Key], #"Content-Type"="application/json"], Query = [query]]))),
    #"Expanded Custom" = Table.ExpandRecordColumn(#"Added Custom1", "Custom", {"calls", "meta"}, {"calls", "meta"}),
x = Table.ExpandListColumn(#"Expanded Custom","calls"),
y= Table.SelectColumns(x,{"calls"})
in
    y;



    

dateFunc= (dat)=>
       if dat = "yesterday" then  Text.Replace(Date.ToText(Date.AddDays(Date.From(DateTime.LocalNow()) , -1),"dd.MM.yyyy"),".","/") 
       else if dat = "today" then Text.Replace(Date.ToText(Date.From(DateTime.LocalNow()),"dd.MM.yyyy"),".","/") 
       else if (try Number.From(Text.BeforeDelimiter(dat,"daysAgo")) otherwise 0) >0 then Text.Replace(Date.ToText(Date.AddDays(Date.From(DateTime.LocalNow()),-1*Number.From(Text.BeforeDelimiter(dat,"daysAgo"))),"dd.MM.yyyy") ,".","/") 
       else  Text.Replace(Date.ToText(Date.From(dat),"dd.MM.yyyy"),".","/") ;



Alloka = [
    TestConnection = (dataSourcePath) => 
        { 
        "Alloka.Data", 
        Json.Document(dataSourcePath)[object_id],
        Json.Document(dataSourcePath)[start],
        Json.Document(dataSourcePath)[end]
        },
    Authentication = [
                 Key = []
       ],
    Label = "Alloka Connection"
];



Alloka.Publish = [
    Beta = false,
    Category = "Other",
    ButtonText = { "Alloka Connector", "Alloka Help" },
    LearnMoreUrl = "https://www.youtube.com/channel/UCqSLNYLN_3mf6nA1Xf7fu1g/",
    SourceImage = Alloka.Icons,
    SourceTypeImage = Alloka.Icons
];



Alloka.Icons = [
    Icon16 = { Extension.Contents("Alloka16.png"), Extension.Contents("Alloka20.png"), Extension.Contents("Alloka24.png"), Extension.Contents("Alloka32.png") },
    Icon32 = { Extension.Contents("Alloka32.png"), Extension.Contents("Alloka40.png"), Extension.Contents("Alloka48.png"), Extension.Contents("Alloka64.png") }
];
