import os

from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node


def generate_launch_description():
    default_params = os.path.join(
        get_package_share_directory('pa_warehouse_status'),
        'config',
        'grand_challenge_params.yaml',
    )
    params_file = LaunchConfiguration('params_file')

    return LaunchDescription([
        DeclareLaunchArgument(
            'params_file',
            default_value=default_params,
            description='Grand Challenge mission controller parameters',
        ),
        # Override the conveyor stopping pose without editing the YAML.
        # A navigation success alone does not prove arm reachability;
        # tune these against the actual simulated box position.
        DeclareLaunchArgument('pickup_x', default_value='5.0'),
        DeclareLaunchArgument('pickup_y', default_value='0.0'),
        DeclareLaunchArgument('pickup_yaw', default_value='3.14159'),
        Node(
            package='pa_warehouse_status',
            executable='warehouse_mission_controller',
            name='warehouse_mission_controller',
            output='screen',
            parameters=[params_file, {
                'pickup_x': LaunchConfiguration('pickup_x'),
                'pickup_y': LaunchConfiguration('pickup_y'),
                'pickup_yaw': LaunchConfiguration('pickup_yaw'),
            }],
        ),
    ])
