page 83262 "DEV Kill Session"
{
    Caption = 'Kill Sessions';
    PageType = List;
    UsageCategory = Lists;
    ApplicationArea = All;
    SourceTable = "Active Session";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("User ID"; "User ID")
                {
                    ApplicationArea = All;
                    StyleExpr = StyleExp;
                    ToolTip = 'Specifies the value of the User ID field';
                }
                field("Session ID"; "Session ID")
                {
                    ApplicationArea = All;
                    StyleExpr = StyleExp;
                    ToolTip = 'Specifies the value of the Session ID field';
                }
                field("Login Datetime"; "Login Datetime")
                {
                    ApplicationArea = All;
                    StyleExpr = StyleExp;
                    ToolTip = 'Specifies the value of the Login Datetime field';
                }

                field("Client Type"; "Client Type")
                {
                    ApplicationArea = All;
                    StyleExpr = StyleExp;
                    ToolTip = 'Specifies the value of the Client Type field';
                }
                field("Client Computer Name"; "Client Computer Name")
                {
                    ApplicationArea = All;
                    StyleExpr = StyleExp;
                    ToolTip = 'Specifies the value of the Client Computer Name field';
                }
                field("Server Instance ID"; "Server Instance ID")
                {
                    ApplicationArea = All;
                    StyleExpr = StyleExp;
                    ToolTip = 'Specifies the value of the Server Instance ID field';
                }
                field("Server Instance Name"; "Server Instance Name")
                {
                    ApplicationArea = All;
                    StyleExpr = StyleExp;
                    ToolTip = 'Specifies the value of the Server Instance Name field';
                }
                field("Database Name"; "Database Name")
                {
                    ApplicationArea = All;
                    StyleExpr = StyleExp;
                    ToolTip = 'Specifies the value of the Database Name field';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Kill)
            {
                Image = Stop;
                Caption = 'Kill Session';
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Kill selected session';

                trigger OnAction();
                var
                    KillMsg: Text;
                begin
                    if "Session ID" = SessionId() then
                        exit;

                    KillMsg := StrSubstNo('%1 killed your current session.', "User ID");
                    ClearLastError();
                    if not StopSession("Session ID", KillMsg) then
                        Error(GetLastErrorText);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        StyleExp := 'standard';
        if "Session ID" = SessionId() then
            StyleExp := 'strong';
    end;

    var
        StyleExp: Text;
}