import java.sql.*;
import java.util.Scanner;

public class Reporting {

    Reporting (String[] userName, String Password) {

    }

    public static void main(String[] args) {

        //System.out.println("In the main function!");

        // Splits up the args into username, pw, and specification
        String username = "sdkfjhs";
        String password = "sdfkjdshs";
        String argString = "5555";

        int arg = 0;

        try {
            username = args[0];
        }
        catch (Exception thirdArgNotFound){
            //System.out.println("No first arg found (big problem)");
        }

        try {
            password = args[1];
        }
        catch (Exception thirdArgNotFound){
            //System.out.println("No second arg found (big problem)");
        }

        try {
            argString = args[2];
            if (args[2].isEmpty() == true) {
                //System.out.println("args[2] is empty!");
                arg = 0;
            }
            else {
                //System.out.println("args[2] isn't empty!");
                arg = Integer.parseInt(argString);
            }
        }
        catch (Exception thirdArgNotFound) {
            //System.out.println("No third arg found (no problem :) )");
        }

        // Test for username, pw, specification
        //System.out.println("Username: " + username);
        //System.out.println("Password: " + password);
        //System.out.println("Arg (specification): " + arg);


        // Open up the class to start the connection
        try {
            Class.forName("oracle.jdbc.driver.OracleDriver");
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        }

        //System.out.println("Right outside the try catch with the if statements!");
        // Start the connection
        try {
            Connection conn = DriverManager.getConnection(
                    "jdbc:oracle:thin:@csorcl.cs.wpi.edu:1521:orcl", username, password);

            //System.out.println("Started the connection!");
            // Call the appropriate function to do the thing:

            if (arg == 0) {
                //System.out.println("In the arg = 0 if statement!");
                NULLReportingOptions(conn);
            }
            else if (arg == 1) {
                //System.out.println("In the arg = 1 if statement!");
                ReportingPatientInfo(conn);
            }
            else if (arg == 2) {
                //System.out.println("In the arg = 2 if statement!");
                ReportingDoctorInfo(conn);
            }
            else if (arg == 3) {
                //System.out.println("In the arg = 3 if statement!");
                ReportingAdmissionsInfo(conn);
            }
            else if (arg == 4) {
                //System.out.println("In the arg = 4 if statement!");
                UpdatingAdmissionPayment(conn);
            }

            conn.close();
            //System.out.println("Ended the connection!");

        } catch (SQLException e) {
            e.printStackTrace();
        }

    }

    // Input of NULL; reports all the options of what you can ask for
    static void NULLReportingOptions(Connection conn) {
        System.out.println("1- Report Patients Basic Information");
        System.out.println("2- Report Doctors Basic Information");
        System.out.println("3- Report Admissions Information");
        System.out.println("4- Update Admissions Payment");
    }

    // Input of 1; reports all patient info when given an SSN
    static void ReportingPatientInfo(Connection conn) {
        //System.out.println("Inside ReportingPatientInfo!");

        // Asks for SSN, takes in SSN
        Scanner input = new Scanner(System.in);

        System.out.print("Enter Patient SSN: ");
        String patientSSN = input.nextLine();

        input.close();

        // Get all the data
        Statement stmt;
        ResultSet rset;
        String query = ("SELECT FirstName, LastName, Street, Town, Zip FROM Patient WHERE SSN = " + patientSSN);
        String FirstName = "firsttt";
        String LastName = "Lastnamee";
        String St = "St";
        String Town = "Town";
        String Zip = "Zip";
        String Address = "Address";

        try {
            stmt = conn.createStatement();
            rset = stmt.executeQuery(query);

            if (rset.next()) {
                FirstName = rset.getString("FirstName");
                LastName = rset.getString("LastName");
                St = rset.getString("Street");
                Town = rset.getString("Town");
                Zip = rset.getString("Zip");

                Address = St + ", " + Town + ", " + Zip;

                // Print out all the data
                System.out.println("Patient SSN: " + patientSSN);
                System.out.println("Patient First Name: " + FirstName);
                System.out.println("Patient Last Name: " + LastName);
                System.out.println("Patient Address: " + Address);
            }
            else   {
                System.out.println("Patient ID not found.");
            }

            rset.close();
            stmt.close();

        } catch (SQLException e) {
            e.printStackTrace();
        }

        input.close();
    }

    // Input of 2: reports all patient
    static void ReportingDoctorInfo(Connection conn) {
        //System.out.println("Inside ReportingDoctorInfo!");

        // Asks for DoctorID, takes in DoctorID
        Scanner input = new Scanner(System.in);

        System.out.print("Enter Doctor ID: ");
        String DoctorID = input.nextLine();

        // Get all the data
        Statement stmt;
        ResultSet rsetEmp;
        ResultSet rsetDoc;

        String queryEmp = "SELECT FirstName, LastName FROM Employee WHERE EmployeeID = " + DoctorID;
        String queryDoc = "SELECT Gender, MedicalSchoolAttended, Specialty FROM Doctor WHERE EmployeeID = " + DoctorID;

        String FirstName = "namee";
        String LastName = "lastnamee";
        String Gender = "sdkfj";
        String GraduatedFrom = "ksdfh";
        String Specialty = "dskfjhd";

        try {
            stmt = conn.createStatement();
            rsetEmp = stmt.executeQuery(queryEmp);

            if (rsetEmp.next()) {
                FirstName = rsetEmp.getString("FirstName");
                LastName = rsetEmp.getString("LastName");

                rsetEmp.close();
                rsetDoc = stmt.executeQuery(queryDoc);

                if (rsetDoc.next()) {
                    Gender = rsetDoc.getString("Gender");
                    GraduatedFrom = rsetDoc.getString("MedicalSchoolAttended");
                    Specialty = rsetDoc.getString("Specialty");

                    // Print all the data
                    System.out.println("Doctor ID: " + DoctorID);
                    System.out.println("Doctor First Name: " + FirstName);
                    System.out.println("Doctor Last Name: " + LastName);
                    System.out.println("Doctor Gender: " + Gender);
                    System.out.println("Doctor Graduated From: " + GraduatedFrom);
                    System.out.println("Doctor Specialty: " + Specialty);
                }
                else {
                    System.out.println("No doctor with this ID found");
                }
                rsetDoc.close();
                stmt.close();
            }
            else {
                System.out.println("No employee with this ID found");
            }

            /*rsetEmp.close();
            rsetDoc = stmt.executeQuery(queryDoc);

            while (rsetDoc.next()) {
                Gender = rsetDoc.getString("Gender");
                GraduatedFrom = rsetDoc.getString("MedicalSchoolAttended");
                Specialty = rsetDoc.getString("Specialty");
            }
            rsetDoc.close();
            stmt.close();

             */

        } catch (SQLException e) {
            e.printStackTrace();
        }

        input.close();
    }

    // Input of 3: reports all Admission info
    static void ReportingAdmissionsInfo(Connection conn) {
        //System.out.println("Inside ReportingAdmissionInfo!");
        Scanner input = new Scanner(System.in);
        String AdmissionNumber;

        // Ask for admission number, take in admission number
        System.out.print("Enter Admission Number: ");
        AdmissionNumber = input.nextLine();
        input.close();

        // Get all the data
        Statement stmt;
        ResultSet rsetAdmNum;
        ResultSet rsetAdmission;
        ResultSet rsetRoomAdmission;
        ResultSet rsetDoctorExaminesAdmission;

        String PatientSSN = "ssn";
        String AdmissionDate = "date";
        String TotalPayment = "monee";
        String RoomNum = "roomnumber";
        String RoomStartDate = "roomstart";
        String RoomEndDate = "roomend";
        String DoctorID = "docID";

        String AdminNumQuery = "SELECT AdmissionNum, StartDate, SSN " +
                "FROM AdmissionNumber WHERE AdmissionNum = "
                + AdmissionNumber;
        String AdmissionQuery = "query";
        String RoomQuery = "query";
        String DoctorQuery = "query";

        try {
            stmt = conn.createStatement();
            rsetAdmNum = stmt.executeQuery(AdminNumQuery);

            // Getting PatientSSN, Admission Start Date from AdmissionNum
            while (rsetAdmNum.next()) {
                PatientSSN = rsetAdmNum.getString("SSN");
                AdmissionDate = rsetAdmNum.getString("StartDate");
            }
            rsetAdmNum.close();

            // Printing out the data so far:
            System.out.println("Admission Number: " + AdmissionNumber);
            System.out.println("Patient SSN: " + PatientSSN);
            System.out.println("Admission Date (start date): " + AdmissionDate);

            AdmissionQuery = "SELECT VisitCost FROM Admission WHERE StartDate = TO_TIMESTAMP('" + AdmissionDate +
                    "', 'YYYY-MM-DD HH24:MI:SS') AND SSN = " + PatientSSN;

            // Get the Total Payment from Admission
            rsetAdmission = stmt.executeQuery(AdmissionQuery);
            while (rsetAdmission.next()) {
                TotalPayment = rsetAdmission.getString("VisitCost");
            }
            rsetAdmission.close();

            RoomQuery = "SELECT RoomNumber, StartDate, EndDate FROM RoomToAdmission WHERE StartDate = " +
                    "TO_TIMESTAMP('" + AdmissionDate + "', 'YYYY-MM-DD HH24:MI:SS') AND SSN = " + PatientSSN;

            // Print out admission total payment:
            System.out.println("Total Payment: " + TotalPayment);

            // Print our "Rooms:"
            System.out.println("Rooms: ");

            // Get room data: Room Num, Room Start Date, Room End Date
            rsetRoomAdmission = stmt.executeQuery(RoomQuery);

            while (rsetRoomAdmission.next()) {
                RoomNum = rsetRoomAdmission.getString("RoomNumber");
                RoomStartDate = rsetRoomAdmission.getString("StartDate");
                RoomEndDate = rsetRoomAdmission.getString("EndDate");

                // Print room data:
                System.out.printf("%-20s %-33s %-33s %n", "    RoomNum: " + RoomNum,
                        "FromDate: " + RoomStartDate, "ToDate: " + RoomEndDate);
            }

            rsetRoomAdmission.close();

            // Print out "Doctors examined the patient in this admission: "
            System.out.println("Doctors examined the patient in this admission: ");

            DoctorQuery = "SELECT EmployeeID FROM DoctorExaminesAdmission WHERE StartDate = " +
                    "TO_TIMESTAMP('" + AdmissionDate + "', 'YYYY-MM-DD HH24:MI:SS') AND SSN = " + PatientSSN;

            // Get doctor data:
            rsetDoctorExaminesAdmission = stmt.executeQuery(DoctorQuery);

            while (rsetDoctorExaminesAdmission.next()) {
                DoctorID = rsetDoctorExaminesAdmission.getString("EmployeeID");

                // Print doctor data:
                System.out.printf("%-25s %n", "    Doctor ID: " + DoctorID);
            }

            rsetDoctorExaminesAdmission.close();

            stmt.close();

        } catch (SQLException e) {
            System.out.println("No admission with this Admission Number found");
            //e.printStackTrace();
        }


    }

    // Input of 4: changes Admission cost
    static void UpdatingAdmissionPayment(Connection conn) {
        //System.out.println("Inside UpdatingAdmissionPayment!");
        Scanner input = new Scanner(System.in);
        String AdmissionNumber;
        String newTotalPayment;
        int totalPaymentInt;

        // Ask for admission number, take in admission number
        System.out.print("Enter Admission Number: ");
        AdmissionNumber = input.nextLine();

        // Ask for new total payment, get new total payment
        System.out.print("Enter the new total payment: ");
        newTotalPayment = input.nextLine();
        totalPaymentInt = Integer.parseInt(newTotalPayment);

        input.close();

        Statement stmt;
        ResultSet rset;
        String query = "UPDATE Admission SET VisitCost = " + newTotalPayment + " WHERE " +
                "StartDate = (SELECT StartDate " +
                "FROM AdmissionNumber " +
                "WHERE AdmissionNum = " + AdmissionNumber + ") AND SSN = (SELECT SSN " +
                "FROM AdmissionNumber " +
                "WHERE AdmissionNum = " + AdmissionNumber + ")";

        try {
            //System.out.println("In the try-catch block!");
            stmt = conn.createStatement();
            //System.out.println("Stmt created!");
            rset = stmt.executeQuery(query);
            //System.out.println("Query executed!");

            //while (rset.next()) {
                //FirstName = rset.getString("FirstName");

                // Print out all the data
                //System.out.println("Patient SSN: " + patientSSN);
            //}

            //rset.close();
            stmt.close();

        } catch (SQLException e) {
            System.out.println("No admission with this Admission Number found");
            //e.printStackTrace();
        }


    }


}
