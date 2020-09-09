page 83261 "DEV View Table"
{
    Caption = 'View Table';
    PageType = List;
    UsageCategory = Lists;
    ApplicationArea = All;
    SourceTable = AllObjWithCaption;
    SourceTableView = where("Object Type" = filter(Table));
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Object ID"; "Object ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Object ID field';
                }
                field("Object Name"; "Object Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Object Name field';

                    trigger OnDrillDown()
                    begin
                        Hyperlink(GetUrl(ClientType::Web, CompanyName, ObjectType::Table, "Object ID"));
                    end;
                }
                field("Object Caption"; "Object Caption")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Object Caption field';
                }
                field(NoOfRecords; NoOfRecords)
                {
                    Caption = 'No. of Records';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the No. of Records" field';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Delete")
            {
                Image = Delete;
                Caption = 'Delete All Data';
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Delete all table records';

                trigger OnAction();
                var
                    RecRef: RecordRef;
                    DeleteRecordsQst: Label 'All records from %1 will be deleted. Continue?', comment = '%1 = Table Name';
                begin
                    if Confirm(DeleteRecordsQst, false, "Object Name") then begin
                        RecRef.Open("Object ID");
                        RecRef.DeleteAll();
                        RecRef.Close();
                    end;
                end;
            }
        }
    }

    var
        NoOfRecords: Integer;

    trigger OnAfterGetRecord()
    var
        RecRef: RecordRef;
    begin
        NoOfRecords := 0;
        RecRef.Open("Object ID");
        NoOfRecords := RecRef.Count();
        RecRef.Close();
    end;
}