/*
 * LK8000 Tactical Flight Computer -  WWW.LK8000.IT
 * Released under GNU/GPL License v.2
 * See CREDITS.TXT file for authors and copyrights
 *
 * File:   iOS/SytemInfo.cpp
 * Author: Nicola Ferruzzi
 *
 * Created on 20 march 2015
 */
#import <UIKit/UIKit.h>
#include "externs.h"
#include <sys/utsname.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#include <mach/mach.h>

void lscpu_init(void)
{
    extern unsigned short HaveSystemInfo;
    HaveSystemInfo = 1;
}

const TCHAR* SystemInfo_Architecture(void) {
    // Based on
    // https://www.theiphonewiki.com/wiki/List_of_iPhones
    // https://www.theiphonewiki.com/wiki/List_of_iPod_touches
    // https://www.theiphonewiki.com/wiki/List_of_iPads
    // https://www.theiphonewiki.com/wiki/List_of_iPad_minis
    static struct utsname systemInfo;
    uname(&systemInfo);
    NSString *internal = [NSString stringWithCString:systemInfo.machine encoding:NSASCIIStringEncoding];

   static NSDictionary *models = @{
        @"i386": @"Simulator",
        @"iPod3,1": @"iPod Touch 3",
        @"iPod4,1": @"iPod Touch 4",
        @"iPod5,1": @"iPod Touch 5",
        @"iPod7,1": @"iPod Touch 6G",
        @"iPhone2,1": @"iPhone 3Gs",
        @"iPhone3,1": @"iPhone 4",
        @"iPhone3,2": @"iPhone 4",
        @"iPhone3,3": @"iPhone 4",
        @"iPhone4,1": @"iPhone 4s",
        @"iPhone5,1": @"iPhone 5",
        @"iPhone5,2": @"iPhone 5",
        @"iPad1,1": @"iPad",
        @"iPad2,1": @"iPad 2",
        @"iPad2,2": @"iPad 2",
        @"iPad2,3": @"iPad 2",
        @"iPad2,4": @"iPad 2",
        @"iPad3,1": @"iPad 3",
        @"iPad3,2": @"iPad 3",
        @"iPad3,3": @"iPad 3",
        @"iPad3,4": @"iPad 4",
        @"iPad3,5": @"iPad 4",
        @"iPad3,6": @"iPad 4",
        @"iPad4,1": @"iPad Air",
        @"iPad4,2": @"iPad Air",
        @"iPad4,3": @"iPad Air",
        @"iPad5,3": @"iPad Air 2",
        @"iPad5,4": @"iPad Air 2",
        @"iPad2,5": @"iPad Mini",
        @"iPad2,6": @"iPad Mini",
        @"iPad2,7": @"iPad Mini",
        @"iPad4,4": @"iPad Mini Retina",
        @"iPad4,5": @"iPad Mini Retina",
        @"iPad4,6": @"iPad Mini Retina",
        @"iPad4,7": @"iPad Mini 3",
        @"iPad4,8": @"iPad Mini 3",
        @"iPad4,9": @"iPad Mini 3",
        @"iPad5,1": @"iPad Mini 4",
        @"iPad5,2": @"iPad Mini 4",
        @"iPad6,7": @"iPad Pro",
        @"iPad6,8": @"iPad Pro",
        @"iPhone6,1": @"iPhone 5s",
        @"iPhone6,2": @"iPhone 5s",
        @"iPhone5,3": @"iPhone 5c",
        @"iPhone5,4": @"iPhone 5c",
        @"iPhone7,1": @"iPhone 6 Plus",
        @"iPhone7,2": @"iPhone 6",
        @"iPhone8,1": @"iPhone 6s",
        @"iPhone8,2": @"iPhone 6s Plus",
    };
    
    NSString *v = [models objectForKey:internal];
    if (!v) return NULL;
    
    static TCHAR val[256];
    memset(val, 0, sizeof(val));
    size_t l = [v lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    l = l > sizeof(val) ? sizeof(val)-1 : l;
    memcpy(val, v.UTF8String, l);
    return val;
}

const TCHAR* SystemInfo_Vendor(void) {
    return _T("APPLE");
}

int SystemInfo_Cpus(void) {
    return (int)[[NSProcessInfo processInfo] activeProcessorCount];
}

unsigned int SystemInfo_Mhz(void) {
    static struct utsname systemInfo;
    uname(&systemInfo);
    NSString *internal = [NSString stringWithCString:systemInfo.machine encoding:NSASCIIStringEncoding];
    
    static NSDictionary *models = @{
        @"i386": @(2700),
        @"iPod3,1": @(620),
        @"iPod4,1": @(1024),
        @"iPod5,1": @(1024),
        @"iPod7,1": @(1100),
        @"iPhone2,1": @(620),
        @"iPhone3,1": @(800),
        @"iPhone3,2": @(800),
        @"iPhone3,3": @(800),
        @"iPhone4,1": @(800),
        @"iPhone5,1": @(1200),
        @"iPhone5,2": @(1200),
        @"iPad1,1": @(1000),
        @"iPad2,1": @(1000),
        @"iPad2,2": @(1000),
        @"iPad2,3": @(1000),
        @"iPad2,4": @(1000),
        @"iPad3,1": @(1000),
        @"iPad3,2": @(1000),
        @"iPad3,3": @(1000),
        @"iPad3,4": @(1400),
        @"iPad3,5": @(1400),
        @"iPad3,6": @(1400),
        @"iPad4,1": @(1400),
        @"iPad4,2": @(1400),
        @"iPad4,3": @(1400),
        @"iPad5,3": @(1500),
        @"iPad5,4": @(1500),
        @"iPad2,5": @(1000),
        @"iPad2,6": @(1000),
        @"iPad2,7": @(1000),
        @"iPad4,4": @(1300),
        @"iPad4,5": @(1300),
        @"iPad4,6": @(1300),
        @"iPad4,7": @(1300),
        @"iPad4,8": @(1300),
        @"iPad4,9": @(1300),
        @"iPad5,1": @(1490),
        @"iPad5,2": @(1490),
        @"iPad6,7": @(2140),
        @"iPad6,8": @(2140),
        @"iPhone6,1": @(1300),
        @"iPhone6,2": @(1300),
        @"iPhone5,3": @(1200),
        @"iPhone5,4": @(1200),
        @"iPhone7,1": @(1380),
        @"iPhone7,2": @(1380),
        @"iPhone8,1": @(1850),
        @"iPhone8,2": @(1850),
    };
    
    NSNumber *v = [models objectForKey:internal];
    // Unknown ? this list is pretty complete so it must be new hardware! (20/3/2016)
    // let's assume at least 1500Mhz
    if (!v) return 1500;

    return [v intValue];
}

unsigned int SystemInfo_Bogomips(void) {
    // Dunno, let's assume ARM 400MHZ is 800 BOGOMIPS :D
    return (SystemInfo_Mhz() / 400) * 800;
}

// Credit to: http://stackoverflow.com/questions/8223348/ios-get-cpu-usage-from-application
int CpuSummary(void) {
    kern_return_t kr;
    task_info_data_t tinfo;
    mach_msg_type_number_t task_info_count;
    
    task_info_count = TASK_INFO_MAX;
    kr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)tinfo, &task_info_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    
    task_basic_info_t      basic_info;
    thread_array_t         thread_list;
    mach_msg_type_number_t thread_count;
    
    thread_info_data_t     thinfo;
    mach_msg_type_number_t thread_info_count;
    
    thread_basic_info_t basic_info_th;
    uint32_t stat_thread = 0; // Mach threads
    
    basic_info = (task_basic_info_t)tinfo;
    
    // get threads in the task
    kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    if (thread_count > 0)
        stat_thread += thread_count;
    
    long tot_sec = 0;
    long tot_usec = 0;
    float tot_cpu = 0;
    int j;
    
    for (j = 0; j < thread_count; j++)
    {
        thread_info_count = THREAD_INFO_MAX;
        kr = thread_info(thread_list[j], THREAD_BASIC_INFO,
                         (thread_info_t)thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS) {
            return -1;
        }
        
        basic_info_th = (thread_basic_info_t)thinfo;
        
        if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
            tot_sec = tot_sec + basic_info_th->user_time.seconds + basic_info_th->system_time.seconds;
            tot_usec = tot_usec + basic_info_th->user_time.microseconds + basic_info_th->system_time.microseconds;
            tot_cpu = tot_cpu + basic_info_th->cpu_usage / (float)TH_USAGE_SCALE * 100.0;
        }
        
    } // for each thread
    
    kr = vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
    assert(kr == KERN_SUCCESS);
    
    return tot_cpu;
}

size_t CheckFreeRam(void) {
    double totalMemory = 0.00;
    vm_statistics_data_t vmStats;
    mach_msg_type_number_t infoCount = HOST_VM_INFO_COUNT;
    kern_return_t kernReturn = host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vmStats, &infoCount);
    if(kernReturn != KERN_SUCCESS) {
        return -1;
    }
    totalMemory = (vm_page_size * vmStats.free_count);
    return (size_t)totalMemory;
}

size_t FindFreeSpace(const char *path) {
    NSString *p = [NSString stringWithUTF8String:path];
    long long freeSpace = [[[[NSFileManager defaultManager] attributesOfFileSystemForPath:p error:nil] objectForKey:NSFileSystemFreeSize] longLongValue];
    return (size_t)freeSpace / 1024;
}

void MyCompactHeaps() {
}


