page 83260 "DEV Change Company"
{
    Caption = 'Select Company';
    PageType = List;
    UsageCategory = Lists;
    ApplicationArea = All;
    SourceTable = Company;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Name; Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Name field. If pressed, opens the selected company.';

                    trigger OnDrillDown()
                    begin
                        Hyperlink(GetUrl(ClientType::Web, Name));
                    end;
                }
                field("Display Name"; "Display Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Display Name field';
                }
            }
        }
    }
}