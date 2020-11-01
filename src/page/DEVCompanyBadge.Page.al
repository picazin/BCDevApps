page 83263 "DEV Company Badge"
{
    ApplicationArea = All;
    Caption = 'Company Information Badge Management';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = Company;
    UsageCategory = Tasks;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Name field';
                }
                field("System Indicator Style"; SystemIndicatorStyle)
                {
                    ApplicationArea = Suite;
                    Caption = 'Company Badge Style';
                    OptionCaption = 'Dark Blue,Light Blue,Dark Green,Light Green,Dark Yellow,Light Yellow,Red,Orange,Deep Purple,Bright Purple';
                    ToolTip = 'Specifies if you want to apply a certain style to the Company Badge. Having different styles on badges can make it easier to recognize the company that you are currently working with.';

                    trigger OnValidate()
                    var
                        CompanyInfo: Record "Company Information";
                    begin
                        if Rec.Name <> CompanyName() then
                            CompanyInfo.ChangeCompany(Rec.Name)
                        else
                            SystemIndicatorChanged := true;

                        CompanyInfo.Get();
                        CompanyInfo."System Indicator Style" := SystemIndicatorStyle;
                        CompanyInfo.Modify();
                    end;
                }
                field("System Indicator Text"; SystemIndicatorText)
                {
                    ApplicationArea = Suite;
                    Caption = 'Company Badge Text';
                    ToolTip = 'Specifies text that you want to use in the Company Badge. Only the first 4 characters will be shown in the badge.';

                    trigger OnValidate()
                    var
                        CompanyInfo: Record "Company Information";
                    begin
                        if Rec.Name <> CompanyName() then
                            CompanyInfo.ChangeCompany(Rec.Name)
                        else
                            SystemIndicatorChanged := true;

                        CompanyInfo.Get();
                        CompanyInfo."Custom System Indicator Text" := SystemIndicatorText;
                        if SystemIndicatorText <> '' then
                            CompanyInfo."System Indicator" := CompanyInfo."System Indicator"::"Custom"
                        else
                            CompanyInfo."System Indicator" := CompanyInfo."System Indicator"::None;
                        CompanyInfo.Modify();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        CompanyInformation: Record "Company Information";
    begin
        if Rec.Name <> CompanyName() then
            CompanyInformation.ChangeCompany(Rec.Name);

        CompanyInformation.Get();
        SystemIndicatorStyle := CompanyInformation."System Indicator Style";
        SystemIndicatorText := CopyStr(CompanyInformation."Custom System Indicator Text", 1, 4);
    end;

    trigger OnClosePage()
    begin
        if SystemIndicatorChanged then begin
            Message(CompanyBadgeRefreshPageTxt);
            RestartSession();
        end;
    end;

    var
        SystemIndicatorChanged: Boolean;
        SystemIndicatorText: Code[4];
        CompanyBadgeRefreshPageTxt: Label 'The Company Badge settings have changed. Refresh the browser (Ctrl+F5) to update the badge.';
        SystemIndicatorStyle: Option "Dark Blue","Light Blue","Dark Green","Light Green","Dark Yellow","Light Yellow",Red,Orange,"Deep Purple","Bright Purple";

    local procedure RestartSession()
    var
        SessionSetting: SessionSettings;
    begin
        SessionSetting.Init();
        SessionSetting.RequestSessionUpdate(false);
    end;
}