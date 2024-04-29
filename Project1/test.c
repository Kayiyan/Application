#include <windows.h>
#include <commctrl.h>
#include <stdlib.h> // Thêm thư viện này để sử dụng hàm free()

#define ID_EDIT_PATH 101
#define ID_BUTTON_START 102
#define ID_LISTVIEW_FILES 103
#define IDD_FILE_LIST_DIALOG 1001
#define WM_ADDITEM (WM_USER + 1)
volatile BOOL isScanning = FALSE;
HANDLE hScanThread = NULL;
CRITICAL_SECTION cs;
// Forward declarations of functions included in this code module:
LRESULT CALLBACK DialogProc(HWND, UINT, WPARAM, LPARAM);
void InitializeListView(HWND);
DWORD WINAPI ScanFiles(LPVOID lpParameter);
void AddItemToListView(HWND hwndListView, LPCWSTR item);
void ScanDirectory(HWND hwnd, const WCHAR* basePath);
void StartScanning(HWND hDlg);
void StopScanning(HWND hDlg);

// Entry point of our application
int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PSTR pCmdLine, int nCmdShow)
{
    // Register common controls like ListView
    INITCOMMONCONTROLSEX icex;
    icex.dwICC = ICC_LISTVIEW_CLASSES;
    InitCommonControlsEx(&icex);

    // Create dialog box
    HWND hwndDialog = CreateDialogParam(hInstance, MAKEINTRESOURCE(IDD_FILE_LIST_DIALOG), 0, DialogProc, 0);
    ShowWindow(hwndDialog, nCmdShow);

    // Main message loop
    MSG msg;
    while (GetMessage(&msg, NULL, 0, 0)) {
        if (!IsDialogMessage(hwndDialog, &msg)) {
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }
    }
    return (int)msg.wParam;
}

void StartScanning(HWND hDlg) {
    WCHAR path[MAX_PATH];
    GetDlgItemTextW(hDlg, ID_EDIT_PATH, path, MAX_PATH);
    ListView_DeleteAllItems(GetDlgItem(hDlg, ID_LISTVIEW_FILES)); // Clear the list view
    isScanning = TRUE;
    EnableWindow(GetDlgItem(hDlg, ID_EDIT_PATH), FALSE); // Disable path edit
    SetDlgItemText(hDlg, ID_BUTTON_START, L"Stop"); // Change button text to "Stop"
    hScanThread = CreateThread(NULL, 0, ScanFiles, hDlg, 0, NULL);
}

void StopScanning(HWND hDlg) {
    isScanning = FALSE; // Signal the ScanFiles thread to stop
    SetDlgItemText(hDlg, ID_BUTTON_START, L"Start"); // Change button text to "Start"
    EnableWindow(GetDlgItem(hDlg, ID_EDIT_PATH), TRUE); // Re-enable path edit
    if (hScanThread) {
        WaitForSingleObject(hScanThread, INFINITE); // Đợi luồng quét hoàn thành
        CloseHandle(hScanThread); // Đóng handle của luồng
        hScanThread = NULL;
    }
}

// Dialog box procedure
LRESULT CALLBACK DialogProc(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam) {
    switch (message) {
    case WM_COMMAND:
        if (LOWORD(wParam) == ID_BUTTON_START) {
            if (!isScanning) {
                StartScanning(hDlg);
            }
            else {
                StopScanning(hDlg);
            }
        }
        break;
    case WM_ADDITEM:
        AddItemToListView(GetDlgItem(hDlg, ID_LISTVIEW_FILES), (LPCWSTR)lParam);
        free((void*)lParam); // Giải phóng bộ nhớ đã cấp phát
        break;
    case WM_INITDIALOG:
        InitializeListView(GetDlgItem(hDlg, ID_LISTVIEW_FILES));
        return (INT_PTR)TRUE;
    case WM_DESTROY:
        StopScanning(hDlg); // Make sure to stop scanning when closing
        PostQuitMessage(0);
        break;
    case WM_CLOSE:
        DestroyWindow(hDlg);
        break;
    }
    return (INT_PTR)FALSE;
}

// Initialize the ListView control
void InitializeListView(HWND hwndListView) {
    // Set up columns in the ListView
    LVCOLUMN lvc = { 0 };
    lvc.mask = LVCF_FMT | LVCF_WIDTH | LVCF_TEXT | LVCF_SUBITEM;
    lvc.fmt = LVCFMT_LEFT;

    lvc.iSubItem = 0;
    lvc.pszText = L"File Path"; // Use the L prefix for a wide string literal
    lvc.cx = 200; // Set the width of the column
    ListView_InsertColumn(hwndListView, 0, &lvc);
}

// Add an item to the ListView
void AddItemToListView(HWND hwndListView, LPCWSTR item) {
    LVITEMW lvi = { 0 };
    lvi.mask = LVIF_TEXT;
    lvi.pszText = (LPWSTR)item; // The cast is safe because item was allocated using _wcsdup
    ListView_InsertItem(hwndListView, &lvi);
}

// Quét các file trong thư mục
DWORD WINAPI ScanFiles(LPVOID lpParameter) {
    HWND hDlg = (HWND)lpParameter;
    WCHAR basePath[MAX_PATH];
    // Lấy đường dẫn từ ô chỉnh sửa văn bản
    GetDlgItemTextW(hDlg, ID_EDIT_PATH, basePath, MAX_PATH);

    // Bắt đầu quét đệ quy
    ScanDirectory(hDlg, basePath);

    // Quét đã hoàn thành hoặc dừng, gửi một thông điệp để đặt lại nút bắt đầu
    PostMessage(hDlg, WM_COMMAND, MAKEWPARAM(ID_BUTTON_START, BN_CLICKED), 0);
    return 0;
}

// Hàm quét thư mục
void ScanDirectory(HWND hwnd, const WCHAR* basePath) {
    WCHAR searchPath[MAX_PATH];
    WIN32_FIND_DATA findData;
    HANDLE hFind;

    // Chuẩn bị đường dẫn tìm kiếm với dấu đại diện để tìm tất cả các file và thư mục
    wsprintf(searchPath, L"%s\\*", basePath);
    hFind = FindFirstFile(searchPath, &findData);

    if (hFind != INVALID_HANDLE_VALUE) {
        do {
            if (!isScanning) {
                break; // Thoát nếu quét đã dừng
            }

            if (findData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
                // Bỏ qua các thư mục "." và ".."
                if (wcscmp(findData.cFileName, L".") != 0 && wcscmp(findData.cFileName, L"..") != 0) {
                    WCHAR nextPath[MAX_PATH];
                    // Xây dựng đường dẫn mới cho thư mục tiếp theo
                    wsprintf(nextPath, L"%s\\%s", basePath, findData.cFileName);
                    // Gọi đệ quy để quét thư mục tiếp theo, nhưng chỉ nếu isScanning vẫn là true
                    if (isScanning) {
                        ScanDirectory(hwnd, nextPath);
                    }
                }
            }
            else {
                WCHAR* fullPath = (WCHAR*)malloc(MAX_PATH * sizeof(WCHAR));
                // Xây dựng đường dẫn đầy đủ cho file
                wsprintf(fullPath, L"%s\\%s", basePath, findData.cFileName);
                // Gửi đường dẫn file tới cửa sổ chính
                PostMessage(hwnd, WM_ADDITEM, 0, (LPARAM)fullPath);
            }
        } while (FindNextFile(hFind, &findData));
        FindClose(hFind);
    }
}